//! Minimal Linux `io_uring` wrapper over `libc` (`SYS_io_uring_setup`,
//! `SYS_io_uring_enter`, and the ring mappings). Zero external dependencies.

use std::io;
use std::os::fd::RawFd;
use std::ptr;
use std::sync::atomic::{AtomicU32, Ordering};

const IORING_OP_READ: u8 = 22;

const IORING_OFF_SQ_RING: i64 = 0;
const IORING_OFF_CQ_RING: i64 = 0x800_0000;
const IORING_OFF_SQES: i64 = 0x1000_0000;

const IORING_FEAT_SINGLE_MMAP: u32 = 1 << 0;
const IORING_ENTER_GETEVENTS: u32 = 1 << 0;

const IORING_SETUP_CQSIZE: u32 = 1 << 3;
const IORING_SETUP_COOP_TASKRUN: u32 = 1 << 8;
const IORING_SETUP_SINGLE_ISSUER: u32 = 1 << 12;
const IORING_SETUP_DEFER_TASKRUN: u32 = 1 << 13;

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct IoSqrOffsets {
    head: u32,
    tail: u32,
    ring_mask: u32,
    ring_entries: u32,
    flags: u32,
    dropped: u32,
    array: u32,
    resv1: u32,
    user_addr: u64,
}

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct IoCqrOffsets {
    head: u32,
    tail: u32,
    ring_mask: u32,
    ring_entries: u32,
    overflow: u32,
    cqes: u32,
    flags: u32,
    resv1: u32,
    user_addr: u64,
}

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct IoUringParams {
    sq_entries: u32,
    cq_entries: u32,
    flags: u32,
    sq_thread_cpu: u32,
    sq_thread_idle: u32,
    features: u32,
    wq_fd: u32,
    resv: [u32; 3],
    sq_off: IoSqrOffsets,
    cq_off: IoCqrOffsets,
}

#[repr(C)]
#[derive(Clone, Copy)]
struct IoUringSqe {
    opcode: u8,
    flags: u8,
    ioprio: u16,
    fd: i32,
    off: u64,
    addr: u64,
    len: u32,
    rw_flags: u32,
    user_data: u64,
    buf_group: u16,
    personality: u16,
    splice_fd_in: i32,
    pad2: [u64; 2],
}

#[repr(C)]
#[derive(Clone, Copy)]
pub(crate) struct IoUringCqe {
    pub user_data: u64,
    pub res: i32,
    pub flags: u32,
}

pub(crate) struct Uring {
    fd: RawFd,
    ring_flags: u32,
    sq_ring_ptr: *mut libc::c_void,
    sq_ring_len: usize,
    cq_ring_ptr: *mut libc::c_void,
    cq_ring_len: usize,
    single_mmap: bool,
    sqes_ptr: *mut IoUringSqe,
    sqes_len: usize,

    sq_head: *const AtomicU32,
    sq_tail: *const AtomicU32,
    sq_mask: u32,
    sq_entries: u32,
    sq_array: *mut u32,
    local_sq_tail: u32,
    unsubmitted: u32,

    cq_head: *const AtomicU32,
    cq_tail: *const AtomicU32,
    cq_mask: u32,
    cqes: *const IoUringCqe,
}

// Each `Uring` is owned by one single-issuer thread at a time.
unsafe impl Send for Uring {}

impl Uring {
    pub(crate) fn new(entries: u32) -> io::Result<Self> {
        let try_flags = [
            IORING_SETUP_CQSIZE | IORING_SETUP_COOP_TASKRUN | IORING_SETUP_SINGLE_ISSUER | IORING_SETUP_DEFER_TASKRUN,
            IORING_SETUP_CQSIZE | IORING_SETUP_COOP_TASKRUN,
            0,
        ];
        let mut params = IoUringParams::default();
        let mut ring_fd: RawFd = -1;
        let mut chosen_flags = 0u32;
        let mut last_err = io::Error::from_raw_os_error(libc::ENOSYS);

        for &flags in &try_flags {
            params = IoUringParams { cq_entries: if flags & IORING_SETUP_CQSIZE != 0 { entries * 2 } else { 0 }, flags, ..IoUringParams::default() };
            // Sound: kernel initializes `params` and returns a new cloexec fd or -1.
            let rc = unsafe { libc::syscall(libc::SYS_io_uring_setup, entries, &mut params as *mut IoUringParams) };
            if rc >= 0 {
                ring_fd = rc as RawFd;
                chosen_flags = flags;
                break;
            }
            last_err = io::Error::last_os_error();
        }
        if ring_fd < 0 {
            return Err(last_err);
        }

        let sq_size = params.sq_off.array as usize + (params.sq_entries as usize) * size_of::<u32>();
        let cq_size = params.cq_off.cqes as usize + (params.cq_entries as usize) * size_of::<IoUringCqe>();
        let single_mmap = (params.features & IORING_FEAT_SINGLE_MMAP) != 0;
        let sq_ring_len = if single_mmap { sq_size.max(cq_size) } else { sq_size };

        // Sound: mapping the ring descriptor at kernel-defined offsets.
        let sq_ring_ptr =
            unsafe { libc::mmap(ptr::null_mut(), sq_ring_len, libc::PROT_READ | libc::PROT_WRITE, libc::MAP_SHARED, ring_fd, IORING_OFF_SQ_RING) };
        if sq_ring_ptr == libc::MAP_FAILED {
            let err = io::Error::last_os_error();
            unsafe { libc::close(ring_fd) };
            return Err(err);
        }

        let (cq_ring_ptr, cq_ring_len) = if single_mmap {
            (sq_ring_ptr, 0)
        } else {
            let p = unsafe { libc::mmap(ptr::null_mut(), cq_size, libc::PROT_READ | libc::PROT_WRITE, libc::MAP_SHARED, ring_fd, IORING_OFF_CQ_RING) };
            if p == libc::MAP_FAILED {
                let err = io::Error::last_os_error();
                unsafe {
                    libc::munmap(sq_ring_ptr, sq_ring_len);
                    libc::close(ring_fd);
                }
                return Err(err);
            }
            (p, cq_size)
        };

        let sqes_len = (params.sq_entries as usize) * size_of::<IoUringSqe>();
        let sqes_raw = unsafe { libc::mmap(ptr::null_mut(), sqes_len, libc::PROT_READ | libc::PROT_WRITE, libc::MAP_SHARED, ring_fd, IORING_OFF_SQES) };
        if sqes_raw == libc::MAP_FAILED {
            let err = io::Error::last_os_error();
            unsafe {
                if !single_mmap {
                    libc::munmap(cq_ring_ptr, cq_ring_len);
                }
                libc::munmap(sq_ring_ptr, sq_ring_len);
                libc::close(ring_fd);
            }
            return Err(err);
        }

        let sq_base = sq_ring_ptr.cast::<u8>();
        let cq_base = cq_ring_ptr.cast::<u8>();
        let sqes_ptr = sqes_raw.cast::<IoUringSqe>();

        let sq_head = unsafe { sq_base.add(params.sq_off.head as usize).cast::<AtomicU32>() };
        let sq_tail = unsafe { sq_base.add(params.sq_off.tail as usize).cast::<AtomicU32>() };
        let sq_mask = unsafe { *sq_base.add(params.sq_off.ring_mask as usize).cast::<u32>() };
        let sq_array = unsafe { sq_base.add(params.sq_off.array as usize).cast::<u32>() };
        for i in 0..params.sq_entries {
            unsafe { *sq_array.add(i as usize) = i };
        }

        let cq_head = unsafe { cq_base.add(params.cq_off.head as usize).cast::<AtomicU32>() };
        let cq_tail = unsafe { cq_base.add(params.cq_off.tail as usize).cast::<AtomicU32>() };
        let cq_mask = unsafe { *cq_base.add(params.cq_off.ring_mask as usize).cast::<u32>() };
        let cqes = unsafe { cq_base.add(params.cq_off.cqes as usize).cast::<IoUringCqe>() };
        let local_sq_tail = unsafe { (*sq_tail).load(Ordering::Relaxed) };

        Ok(Self {
            fd: ring_fd,
            ring_flags: chosen_flags,
            sq_ring_ptr,
            sq_ring_len,
            cq_ring_ptr,
            cq_ring_len,
            single_mmap,
            sqes_ptr,
            sqes_len,
            sq_head,
            sq_tail,
            sq_mask,
            sq_entries: params.sq_entries,
            sq_array,
            local_sq_tail,
            unsubmitted: 0,
            cq_head,
            cq_tail,
            cq_mask,
            cqes,
        })
    }

    #[inline]
    pub(crate) fn sq_space_left(&self) -> u32 {
        let head = unsafe { (*self.sq_head).load(Ordering::Acquire) };
        self.sq_entries - (self.local_sq_tail.wrapping_sub(head))
    }

    #[inline]
    pub(crate) fn unsubmitted(&self) -> u32 {
        self.unsubmitted
    }

    /// Queue an `IORING_OP_READ` SQE. Caller must ensure `buf[..len]` stays
    /// valid and exclusively writable by the kernel until the matching CQE is
    /// reaped.
    #[inline]
    pub(crate) unsafe fn push_read(&mut self, fd: RawFd, buf: *mut u8, len: u32, offset: u64, rw_flags: u32, user_data: u64) -> bool {
        if self.sq_space_left() == 0 {
            return false;
        }
        let idx = (self.local_sq_tail & self.sq_mask) as usize;
        unsafe {
            *self.sq_array.add(idx) = idx as u32;
            *self.sqes_ptr.add(idx) = IoUringSqe {
                opcode: IORING_OP_READ,
                flags: 0,
                ioprio: 0,
                fd,
                off: offset,
                addr: buf as usize as u64,
                len,
                rw_flags,
                user_data,
                buf_group: 0,
                personality: 0,
                splice_fd_in: 0,
                pad2: [0; 2],
            };
        }
        self.local_sq_tail = self.local_sq_tail.wrapping_add(1);
        self.unsubmitted += 1;
        true
    }

    /// Submit all queued SQEs and wait for at least `min_complete` CQEs.
    pub(crate) fn submit_and_wait(&mut self, min_complete: u32) -> io::Result<()> {
        if self.unsubmitted > 0 {
            unsafe { (*self.sq_tail).store(self.local_sq_tail, Ordering::Release) };
        }
        let mut to_submit = self.unsubmitted;
        self.unsubmitted = 0;

        // With DEFER_TASKRUN, GETEVENTS runs pending task_work even when min_complete == 0.
        let need_getevents = min_complete > 0 || (self.ring_flags & IORING_SETUP_DEFER_TASKRUN) != 0;
        if to_submit == 0 && min_complete == 0 && !need_getevents {
            return Ok(());
        }
        let enter_flags = if need_getevents { IORING_ENTER_GETEVENTS } else { 0 };

        loop {
            let rc = unsafe {
                libc::syscall(
                    libc::SYS_io_uring_enter,
                    self.fd,
                    to_submit,
                    min_complete,
                    enter_flags,
                    ptr::null::<libc::sigset_t>(),
                    size_of::<libc::sigset_t>(),
                )
            };
            if rc >= 0 {
                let submitted = rc as u32;
                to_submit = to_submit.saturating_sub(submitted);
                if to_submit == 0 {
                    return Ok(());
                }
                continue;
            }
            let err = io::Error::last_os_error();
            if err.kind() == io::ErrorKind::Interrupted {
                // Kernel may have consumed some or all SQEs from sq_head before EINTR.
                let head = unsafe { (*self.sq_head).load(Ordering::Acquire) };
                to_submit = self.local_sq_tail.wrapping_sub(head);
                if min_complete == 0 && to_submit == 0 {
                    return Ok(());
                }
                continue;
            }
            return Err(err);
        }
    }

    #[inline]
    pub(crate) fn pop_cqe(&mut self) -> Option<IoUringCqe> {
        let head = unsafe { (*self.cq_head).load(Ordering::Relaxed) };
        let tail = unsafe { (*self.cq_tail).load(Ordering::Acquire) };
        if head == tail {
            return None;
        }
        let idx = (head & self.cq_mask) as usize;
        let cqe = unsafe { *self.cqes.add(idx) };
        unsafe { (*self.cq_head).store(head.wrapping_add(1), Ordering::Release) };
        Some(cqe)
    }
}

impl Drop for Uring {
    fn drop(&mut self) {
        unsafe {
            libc::munmap(self.sqes_ptr.cast(), self.sqes_len);
            if !self.single_mmap {
                libc::munmap(self.cq_ring_ptr, self.cq_ring_len);
            }
            libc::munmap(self.sq_ring_ptr, self.sq_ring_len);
            libc::close(self.fd);
        }
    }
}

#[cfg(test)]
mod test {
    use super::Uring;
    use std::os::fd::AsRawFd;

    #[test]
    fn uring_reads_multiple_files_and_offsets() {
        let Ok(mut ring) = Uring::new(16) else { return };
        let dir = tempfile::tempdir().unwrap();
        let mut files = Vec::new();
        let mut bufs = Vec::new();
        for i in 0..8usize {
            let p = dir.path().join(format!("f{i}"));
            let data: Vec<u8> = (0..(i * 1111 + 17)).map(|k| (k * 13 + i) as u8).collect();
            std::fs::write(&p, &data).unwrap();
            files.push((std::fs::File::open(&p).unwrap(), data));
            bufs.push(vec![0u8; i * 1111 + 32]);
        }
        for (i, ((f, _), buf)) in files.iter().zip(bufs.iter_mut()).enumerate() {
            assert!(unsafe { ring.push_read(f.as_raw_fd(), buf.as_mut_ptr(), buf.len() as u32, 0, 0, i as u64) });
        }
        ring.submit_and_wait(8).unwrap();
        let mut seen = 0usize;
        while let Some(cqe) = ring.pop_cqe() {
            let i = cqe.user_data as usize;
            let want = &files[i].1;
            assert_eq!(cqe.res as usize, want.len());
            assert_eq!(&bufs[i][..want.len()], &want[..]);
            seen += 1;
        }
        assert_eq!(seen, 8);
    }
}
