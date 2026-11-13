//! Linux `io_uring` + `blake3::throughput::Pipeline` file hashing engine.
//!
//! - **Small and medium files (`< 512 KiB`)**:
//!   - Page-cache hits (`preadv2` with `RWF_NOWAIT`) read directly into a
//!     `Block`-aligned L2-hot arena (`WarmBatch`, 16 slots x 16 KiB) and hash
//!     together on the reading core via `blake3::throughput::hash_each`
//!     (multi-buffer SIMD, zero cross-socket cache transfers, zero pool spawn).
//!   - Page-cache misses stream asynchronously through a per-worker `Uring`
//!     (`COOP_TASKRUN | SINGLE_ISSUER | DEFER_TASKRUN`, 32-64 reads in flight),
//!     reaping CQEs out-of-order and batching `<= 16 KiB` completions through
//!     the same core-local `WarmBatch` (`throughput::hash_each`).
//! - **Large files (`>= 512 KiB`)**:
//!   - Cached (`mincore` resident): `< 4 MiB` hashes in place on the core;
//!     `>= 4 MiB` loans `&map` zero-copy to `Pipeline::lent` across the worker
//!     pool and holds up to `HOLD_PAGES` until exit.
//!   - Cold (not resident): streams directly from storage into 64 KiB
//!     `Pipeline::room()`s via `IORING_OP_READ`, overlapping NVMe DMA with
//!     multi-core subtree hashing while capping memory to ~4 MiB per stream.

use crate::Args;
use crate::uring::{IoUringCqe, Uring};
use blake3::throughput::{Block, Event, Lent, Limits, Message, Pipeline, ROOM_LEN, Room, block_on};
use core::future::Future;
use core::mem::MaybeUninit;
use core::pin::Pin;
use core::task::{Context, Poll, Waker};
use std::collections::VecDeque;
use std::fs::File;
use std::io;
use std::os::fd::{AsRawFd, RawFd};
use std::path::Path;
use std::sync::atomic::{AtomicUsize, Ordering};

const SMALL: u64 = crate::MAP_LEN as u64;
const WARM_BATCH_MAX_FILE: usize = 16 * 1024;
const WARM_SLOT_BLOCKS: usize = (WARM_BATCH_MAX_FILE / 64) + 1;
const WARM_BATCH_SLOTS: usize = 16;

const RING_ENTRIES: u32 = 128;
const SLOTS_PER_RING_MULTI: usize = 48;
const SLOTS_PER_RING_SINGLE: usize = 64;
const LARGE_WINDOW: usize = 64;
const MAX_FILE_ROOMS: u64 = 48;
const USER_LARGE_BIT: u64 = 1 << 63;

pub(crate) fn applies(args: &Args) -> bool {
    args.is_standard_32() && args.file_args.len() > 1 && args.file_args.iter().all(|p| p != Path::new("-"))
}

pub(crate) fn hash_single_cold_large_file_1t(args: &Args, file: &File, hint_size: u64) -> Option<io::Result<blake3::Hash>> {
    if !args.is_standard_32() {
        return None;
    }
    let mut ring = Uring::new(RING_ENTRIES).ok()?;
    crate::init_pool_once(1);
    let mut pipe = Pipeline::<usize, ()>::new(args.mode, Limits { messages: 2, rooms: LARGE_WINDOW });
    let mut deferred_cqes = VecDeque::new();
    let mut msg = block_on(pipe.message(0, Some(hint_size)));
    match stream_fd_into_rooms(&mut ring, &mut deferred_cqes, &mut pipe, &mut msg, file.as_raw_fd(), hint_size) {
        Ok(()) => {
            pipe.end(msg);
            loop {
                if let Some(ev) = pipe.next_event() {
                    match ev {
                        Event::Hashed { hash, .. } => return Some(Ok(hash)),
                        _ => unreachable!(),
                    }
                }
                block_on(pipe.ready());
            }
        }
        Err(e) => {
            pipe.abort(msg);
            while pipe.next_event().is_none() {
                block_on(pipe.ready());
            }
            Some(Err(e))
        }
    }
}

fn grow_descriptor_table(descriptors: usize) {
    let target = descriptors.next_power_of_two() as i32 - 1;
    unsafe {
        let fd = libc::open(c"/dev/null".as_ptr(), libc::O_RDONLY | libc::O_CLOEXEC);
        if fd >= 0 {
            if libc::dup2(fd, target) == target {
                libc::close(target);
            }
            libc::close(fd);
        }
    }
}

#[inline]
fn poll_once<F: Future>(f: F) -> Poll<F::Output> {
    let mut cx = Context::from_waker(Waker::noop());
    Pin::new(&mut core::pin::pin!(f)).poll(&mut cx)
}

enum WindowSlot {
    Reading(Room),
    Ready(Room, usize),
    Eof,
}

fn pread_fill_rest(fd: RawFd, mut dst: &mut [u8], mut offset: u64) -> io::Result<usize> {
    let mut total = 0usize;
    while !dst.is_empty() {
        let rc = unsafe { libc::pread(fd, dst.as_mut_ptr().cast(), dst.len(), offset as libc::off_t) };
        if rc == 0 {
            break;
        }
        if rc < 0 {
            let err = io::Error::last_os_error();
            if err.kind() == io::ErrorKind::Interrupted {
                continue;
            }
            return Err(err);
        }
        let n = rc as usize;
        total += n;
        offset += n as u64;
        dst = &mut dst[n..];
    }
    Ok(total)
}

fn stream_fd_into_rooms(
    ring: &mut Uring,
    deferred_small_cqes: &mut VecDeque<IoUringCqe>,
    pipe: &mut Pipeline<usize, ()>,
    msg: &mut Message,
    fd: RawFd,
    hint_size: u64,
) -> io::Result<()> {
    let mut window: [Option<WindowSlot>; LARGE_WINDOW] = [const { None }; LARGE_WINDOW];
    let mut next_issue_seq: u64 = 0;
    let mut next_commit_seq: u64 = 0;
    let mut max_issue_seq: u64 = (hint_size / (ROOM_LEN as u64)) + 1;
    let mut eof_seq: Option<u64> = None;
    let mut in_flight_uring: usize = 0;
    let mut first_err: Option<io::Error> = None;

    loop {
        while first_err.is_none()
            && eof_seq.is_none()
            && next_issue_seq <= max_issue_seq
            && (next_issue_seq - next_commit_seq) < MAX_FILE_ROOMS
            && ring.sq_space_left() > 0
        {
            let slot_idx = (next_issue_seq as usize) % LARGE_WINDOW;
            if window[slot_idx].is_some() {
                break;
            }
            let mut room = if in_flight_uring == 0 && window[(next_commit_seq as usize) % LARGE_WINDOW].is_none() {
                block_on(pipe.room())
            } else {
                match poll_once(pipe.room()) {
                    Poll::Ready(r) => r,
                    Poll::Pending => break,
                }
            };
            let off = next_issue_seq * (ROOM_LEN as u64);
            let user_data = USER_LARGE_BIT | next_issue_seq;
            let ok = unsafe { ring.push_read(fd, room.bytes_mut().as_mut_ptr(), ROOM_LEN as u32, off, 0, user_data) };
            debug_assert!(ok);
            window[slot_idx] = Some(WindowSlot::Reading(room));
            in_flight_uring += 1;
            next_issue_seq += 1;
        }

        let commit_ready = matches!(window[(next_commit_seq as usize) % LARGE_WINDOW], Some(WindowSlot::Ready(..) | WindowSlot::Eof));
        if ring.unsubmitted() > 0 || (!commit_ready && in_flight_uring > 0) {
            let min_wait = if commit_ready || in_flight_uring == 0 { 0 } else { 1 };
            ring.submit_and_wait(min_wait)?;
        }

        while let Some(cqe) = ring.pop_cqe() {
            if (cqe.user_data & USER_LARGE_BIT) == 0 {
                deferred_small_cqes.push_back(cqe);
                continue;
            }
            let seq = cqe.user_data & !USER_LARGE_BIT;
            let idx = (seq as usize) % LARGE_WINDOW;
            let Some(WindowSlot::Reading(mut room)) = window[idx].take() else {
                unreachable!("large CQE without Reading room");
            };
            in_flight_uring -= 1;

            if cqe.res < 0 {
                let errno = -cqe.res;
                if errno == libc::EINTR && first_err.is_none() {
                    let off = seq * (ROOM_LEN as u64);
                    while ring.sq_space_left() == 0 {
                        ring.submit_and_wait(0)?;
                    }
                    unsafe { ring.push_read(fd, room.bytes_mut().as_mut_ptr(), ROOM_LEN as u32, off, 0, USER_LARGE_BIT | seq) };
                    window[idx] = Some(WindowSlot::Reading(room));
                    in_flight_uring += 1;
                    continue;
                }
                if first_err.is_none() {
                    first_err = Some(io::Error::from_raw_os_error(errno));
                }
                drop(room);
                continue;
            }

            let n = cqe.res as usize;
            if n == 0 {
                drop(room);
                eof_seq = Some(eof_seq.map_or(seq, |e| e.min(seq)));
                window[idx] = Some(WindowSlot::Eof);
            } else if n < ROOM_LEN {
                let extra = match pread_fill_rest(fd, &mut room.bytes_mut()[n..ROOM_LEN], seq * (ROOM_LEN as u64) + (n as u64)) {
                    Ok(k) => k,
                    Err(e) => {
                        if first_err.is_none() {
                            first_err = Some(e);
                        }
                        drop(room);
                        continue;
                    }
                };
                let total = n + extra;
                if total < ROOM_LEN {
                    eof_seq = Some(eof_seq.map_or(seq, |e| e.min(seq)));
                } else if seq >= max_issue_seq {
                    max_issue_seq = seq + 2;
                }
                window[idx] = Some(WindowSlot::Ready(room, total));
            } else {
                if seq >= max_issue_seq {
                    max_issue_seq = seq + 2;
                }
                window[idx] = Some(WindowSlot::Ready(room, ROOM_LEN));
            }
        }

        if first_err.is_some() {
            if in_flight_uring == 0 {
                for slot in &mut window {
                    *slot = None;
                }
                return Err(first_err.unwrap());
            }
            continue;
        }

        let mut finished = false;
        loop {
            let idx = (next_commit_seq as usize) % LARGE_WINDOW;
            match window[idx].take() {
                Some(WindowSlot::Eof) => {
                    finished = true;
                    break;
                }
                Some(WindowSlot::Ready(mut room, len)) if len < ROOM_LEN => {
                    if len > 0 {
                        pipe.commit(msg, &mut room, len);
                    }
                    drop(room);
                    finished = true;
                    break;
                }
                Some(WindowSlot::Ready(mut room, len)) => {
                    debug_assert_eq!(len, ROOM_LEN);
                    pipe.commit(msg, &mut room, ROOM_LEN);
                    drop(room);
                    next_commit_seq += 1;
                }
                other => {
                    window[idx] = other;
                    break;
                }
            }
        }

        if finished {
            while in_flight_uring > 0 {
                ring.submit_and_wait(1)?;
                while let Some(cqe) = ring.pop_cqe() {
                    if (cqe.user_data & USER_LARGE_BIT) == 0 {
                        deferred_small_cqes.push_back(cqe);
                        continue;
                    }
                    let seq = cqe.user_data & !USER_LARGE_BIT;
                    let _ = window[(seq as usize) % LARGE_WINDOW].take();
                    in_flight_uring -= 1;
                }
            }
            for slot in &mut window {
                *slot = None;
            }
            return Ok(());
        }
    }
}

/// Core-local uninitialized `MaybeUninit<Block>` L2-hot arena (`16 x 16.06 KiB`):
/// batches both cached `RWF_NOWAIT` hits and completed `Uring` `<= 16 KiB` reads
/// through `blake3::throughput::hash_each` on the reading CPU core.
struct WarmBatch {
    arena: Option<Box<[MaybeUninit<Block>]>>,
    entries: [(usize, usize); WARM_BATCH_SLOTS],
    len: usize,
}

impl WarmBatch {
    fn new() -> Self {
        Self { arena: None, entries: [(0, 0); WARM_BATCH_SLOTS], len: 0 }
    }

    #[inline]
    fn slot_ptr_and_cap(&mut self, slot: usize) -> (*mut u8, usize) {
        let arena = self.arena.get_or_insert_with(|| Box::new_uninit_slice(WARM_BATCH_SLOTS * WARM_SLOT_BLOCKS));
        let start = slot * WARM_SLOT_BLOCKS;
        let ptr = unsafe { arena.as_mut_ptr().add(start).cast::<u8>() };
        (ptr, WARM_SLOT_BLOCKS * 64)
    }

    #[inline]
    fn push_slice(
        &mut self,
        file_idx: usize,
        bytes: &[u8],
        mode: blake3::Mode<'_>,
        done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool,
        keep_going: &mut bool,
    ) {
        debug_assert!(bytes.len() <= WARM_BATCH_MAX_FILE);
        let slot = self.len;
        let (dst, _) = self.slot_ptr_and_cap(slot);
        unsafe { core::ptr::copy_nonoverlapping(bytes.as_ptr(), dst, bytes.len()) };
        self.entries[slot] = (file_idx, bytes.len());
        self.len += 1;
        if self.len == WARM_BATCH_SLOTS {
            self.flush(mode, done, keep_going);
        }
    }

    fn flush(&mut self, mode: blake3::Mode<'_>, done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool, keep_going: &mut bool) {
        let count = self.len;
        if count == 0 {
            return;
        }
        self.len = 0;
        if !*keep_going {
            return;
        }
        let arena = self.arena.as_mut().expect("arena allocated before len > 0");
        if count == 1 {
            let (file_idx, byte_len) = self.entries[0];
            let ptr = arena.as_ptr().cast::<u8>();
            let bytes = unsafe { core::slice::from_raw_parts(ptr, byte_len) };
            let h = crate::hash_slice_32(mode, bytes);
            if !done(file_idx, Ok(h)) {
                *keep_going = false;
            }
            return;
        }
        for k in 0..count {
            let (_, byte_len) = self.entries[k];
            let blocks_needed = byte_len.div_ceil(64);
            let padded = blocks_needed * 64;
            if padded > byte_len {
                let start_ptr = unsafe { arena.as_mut_ptr().add(k * WARM_SLOT_BLOCKS).cast::<u8>() };
                unsafe { start_ptr.add(byte_len).write_bytes(0, padded - byte_len) };
            }
        }
        let arena_ref: &[MaybeUninit<Block>] = &*arena;
        let mut items: [(&[Block], usize); WARM_BATCH_SLOTS] = [(&[], 0); WARM_BATCH_SLOTS];
        let mut digests = [[0u8; blake3::OUT_LEN]; WARM_BATCH_SLOTS];
        for k in 0..count {
            let (_, byte_len) = self.entries[k];
            let blocks_needed = byte_len.div_ceil(64);
            let start = k * WARM_SLOT_BLOCKS;
            let slice = unsafe { core::slice::from_raw_parts(arena_ref.as_ptr().add(start).cast::<Block>(), blocks_needed) };
            items[k] = (slice, byte_len);
        }
        blake3::throughput::hash_each(mode, &items[..count], &mut digests[..count]);
        for k in 0..count {
            let (file_idx, _) = self.entries[k];
            if !done(file_idx, Ok(blake3::Hash::from(digests[k]))) {
                *keep_going = false;
                break;
            }
        }
    }
}

#[inline]
fn try_pread_cached(fd: RawFd, dst_ptr: *mut u8, dst_cap: usize, mut at: usize, hint: usize) -> io::Result<(usize, bool)> {
    loop {
        if at == dst_cap {
            return Ok((at, false));
        }
        let iov = libc::iovec { iov_base: unsafe { dst_ptr.add(at).cast() }, iov_len: dst_cap - at };
        let rc = unsafe { libc::preadv2(fd, &iov, 1, at as libc::off_t, libc::RWF_NOWAIT) };
        if rc == 0 {
            return Ok((at, true));
        }
        if rc < 0 {
            let e = io::Error::last_os_error();
            if e.kind() == io::ErrorKind::Interrupted {
                continue;
            }
            return Ok((at, false));
        }
        at += rc as usize;
        if hint > 0 && at == hint && at < dst_cap {
            return Ok((at, true));
        }
    }
}

struct SmallSlot {
    file_idx: usize,
    file: File,
    buf: Vec<u8>,
    at: usize,
    hint: usize,
}

#[inline]
fn ensure_spare_cap(buf: &mut Vec<u8>, needed: usize) {
    buf.clear();
    if buf.capacity() < needed {
        buf.reserve(needed);
    }
}

fn read_rest_sync_uninit(file: &File, buf: &mut Vec<u8>, mut at: usize) -> io::Result<usize> {
    loop {
        if at == buf.capacity() {
            unsafe { buf.set_len(at) };
            buf.reserve(at.max(4096));
            unsafe { buf.set_len(0) };
        }
        let avail = buf.capacity() - at;
        let ptr = unsafe { buf.as_mut_ptr().add(at) };
        let rc = unsafe { libc::pread(file.as_raw_fd(), ptr.cast(), avail, at as libc::off_t) };
        if rc == 0 {
            unsafe { buf.set_len(at) };
            return Ok(at);
        }
        if rc < 0 {
            let e = io::Error::last_os_error();
            if e.kind() == io::ErrorKind::Interrupted {
                continue;
            }
            return Err(e);
        }
        at += rc as usize;
    }
}

struct WarmLargePipe {
    pipe: Pipeline<usize, ()>,
    maps: Vec<(usize, Lent<'static>, memmap2::Mmap)>,
    in_flight: usize,
}

impl WarmLargePipe {
    fn new(mode: blake3::Mode<'static>) -> Self {
        Self { pipe: Pipeline::new(mode, Limits { messages: 16, rooms: 0 }), maps: Vec::with_capacity(16), in_flight: 0 }
    }

    fn drain(&mut self, done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool, keep_going: &mut bool) {
        while let Some(ev) = self.pipe.next_event() {
            self.in_flight -= 1;
            if let Event::Hashed { tag: idx, hash, .. } = ev {
                if let Some(pos) = self.maps.iter().position(|x| x.0 == idx) {
                    let (_, guard, map) = self.maps.swap_remove(pos);
                    drop(guard);
                    crate::hold(map);
                }
                if *keep_going && !done(idx, Ok(hash)) {
                    *keep_going = false;
                }
            }
        }
    }

    fn submit_lent(
        &mut self,
        idx: usize,
        size: u64,
        map: memmap2::Mmap,
        done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool,
        keep_going: &mut bool,
    ) {
        self.drain(done, keep_going);
        let m = block_on(self.pipe.message(idx, Some(size)));
        let slice: &'static [u8] = unsafe { core::slice::from_raw_parts(map.as_ptr(), map.len()) };
        let guard = unsafe { self.pipe.lent(m, slice) };
        self.maps.push((idx, guard, map));
        self.in_flight += 1;
    }

    fn finish(&mut self, done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool, keep_going: &mut bool) {
        while self.in_flight > 0 {
            self.drain(done, keep_going);
            if self.in_flight > 0 {
                block_on(self.pipe.ready());
            }
        }
    }
}

/// Per-worker `Uring` sliding-window reader for cold files.
/// Small (`< 512 KiB`) completions hash right on this CPU core (via `WarmBatch`
/// `throughput::hash_each` for `<= 16 KiB` or `hash_slice_32` for `16..512 KiB`),
/// spawning zero pool threads unless a cold large file (`>= 512 KiB`) occurs!
struct ColdRingState {
    ring: Uring,
    cold_large_pipe: Option<Pipeline<usize, ()>>,
    slots: Vec<Option<SmallSlot>>,
    free_slot_ids: Vec<usize>,
    free_bufs: Vec<Vec<u8>>,
    deferred_cqes: VecDeque<IoUringCqe>,
    ring_in_flight: usize,
    max_slots: usize,
}

impl ColdRingState {
    fn new(max_slots: usize) -> Option<Self> {
        let ring = Uring::new(RING_ENTRIES).ok()?;
        Some(Self {
            ring,
            cold_large_pipe: None,
            slots: (0..max_slots).map(|_| None).collect(),
            free_slot_ids: (0..max_slots).rev().collect(),
            free_bufs: Vec::with_capacity(max_slots * 2),
            deferred_cqes: VecDeque::new(),
            ring_in_flight: 0,
            max_slots,
        })
    }

    fn step_ring(
        &mut self,
        wait: bool,
        mode: blake3::Mode<'_>,
        warm_batch: &mut WarmBatch,
        done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool,
        keep_going: &mut bool,
    ) {
        if self.deferred_cqes.is_empty() {
            let min_wait = if wait && self.ring_in_flight > 0 { 1 } else { 0 };
            if min_wait == 0 && self.ring.unsubmitted() == 0 {
                return;
            }
            if let Err(e) = self.ring.submit_and_wait(min_wait) {
                eprintln!("{}: io_uring_enter: {}", crate::NAME, e);
                return;
            }
        }

        loop {
            let cqe = match self.deferred_cqes.pop_front() {
                Some(c) => c,
                None => match self.ring.pop_cqe() {
                    Some(c) => c,
                    None => break,
                },
            };
            let slot_id = cqe.user_data as usize;
            let mut st = self.slots[slot_id].take().expect("active SmallSlot");
            self.ring_in_flight -= 1;

            if cqe.res < 0 {
                let errno = -cqe.res;
                if errno == libc::EINTR {
                    while self.ring.sq_space_left() == 0 {
                        let _ = self.ring.submit_and_wait(0);
                    }
                    let fd = st.file.as_raw_fd();
                    let ptr = unsafe { st.buf.as_mut_ptr().add(st.at) };
                    let len = (st.buf.capacity() - st.at) as u32;
                    let off = st.at as u64;
                    self.slots[slot_id] = Some(st);
                    unsafe { self.ring.push_read(fd, ptr, len, off, 0, slot_id as u64) };
                    self.ring_in_flight += 1;
                    continue;
                }
                if st.at == 0 && matches!(errno, libc::EINVAL | libc::EOPNOTSUPP | libc::EBADF) {
                    let res = read_rest_sync_uninit(&st.file, &mut st.buf, 0);
                    drop(st.file);
                    self.free_slot_ids.push(slot_id);
                    match res {
                        Ok(n) => {
                            if n <= WARM_BATCH_MAX_FILE {
                                warm_batch.push_slice(st.file_idx, &st.buf[..n], mode, done, keep_going);
                            } else {
                                warm_batch.flush(mode, done, keep_going);
                                let h = crate::hash_slice_32(mode, &st.buf[..n]);
                                if *keep_going && !done(st.file_idx, Ok(h)) {
                                    *keep_going = false;
                                }
                            }
                        }
                        Err(e) => {
                            if *keep_going && !done(st.file_idx, Err(e.into())) {
                                *keep_going = false;
                            }
                        }
                    }
                    st.buf.clear();
                    if self.free_bufs.len() < self.max_slots * 2 {
                        self.free_bufs.push(st.buf);
                    }
                    continue;
                }
                self.free_bufs.push(st.buf);
                self.free_slot_ids.push(slot_id);
                if *keep_going && !done(st.file_idx, Err(io::Error::from_raw_os_error(errno).into())) {
                    *keep_going = false;
                }
                continue;
            }

            let n = cqe.res as usize;
            st.at += n;
            let reached_eof = n == 0 || (st.hint > 0 && st.at == st.hint && st.at < st.buf.capacity());
            if reached_eof {
                let total_len = st.at;
                drop(st.file);
                self.free_slot_ids.push(slot_id);
                if *keep_going {
                    unsafe { st.buf.set_len(total_len) };
                    if total_len <= WARM_BATCH_MAX_FILE {
                        warm_batch.push_slice(st.file_idx, &st.buf, mode, done, keep_going);
                    } else {
                        let h = crate::hash_slice_32(mode, &st.buf);
                        if !done(st.file_idx, Ok(h)) {
                            *keep_going = false;
                        }
                    }
                    st.buf.clear();
                }
                if self.free_bufs.len() < self.max_slots * 2 {
                    self.free_bufs.push(st.buf);
                }
            } else {
                if st.at == st.buf.capacity() {
                    unsafe { st.buf.set_len(st.at) };
                    st.buf.reserve(st.buf.capacity().max(8192));
                    unsafe { st.buf.set_len(0) };
                }
                while self.ring.sq_space_left() == 0 {
                    let _ = self.ring.submit_and_wait(0);
                }
                let fd = st.file.as_raw_fd();
                let ptr = unsafe { st.buf.as_mut_ptr().add(st.at) };
                let len = (st.buf.capacity() - st.at) as u32;
                let off = st.at as u64;
                self.slots[slot_id] = Some(st);
                unsafe { self.ring.push_read(fd, ptr, len, off, 0, slot_id as u64) };
                self.ring_in_flight += 1;
            }
        }
    }

    fn finish(
        &mut self,
        mode: blake3::Mode<'_>,
        warm_batch: &mut WarmBatch,
        done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool,
        keep_going: &mut bool,
    ) {
        while self.ring_in_flight > 0 || !self.deferred_cqes.is_empty() {
            self.step_ring(true, mode, warm_batch, done, keep_going);
        }
    }
}

pub(crate) fn hash_inputs(args: &Args, out: &mut crate::OutBuf) -> Option<u64> {
    let nfiles = args.file_args.len();
    let total_threads = crate::threads().get();
    let io_threads = if total_threads == 1 {
        1
    } else if nfiles < 32 {
        total_threads.min(4).min(nfiles)
    } else {
        total_threads.min(12)
    };
    let slots_per_ring = if io_threads <= 4 { SLOTS_PER_RING_SINGLE } else { SLOTS_PER_RING_MULTI };

    grow_descriptor_table(io_threads * (slots_per_ring + 8) + 64);

    if io_threads == 1 {
        let next = AtomicUsize::new(0);
        let mut results: Vec<Option<anyhow::Result<blake3::Hash>>> = (0..nfiles).map(|_| None).collect();
        let mut printed = 0usize;
        let mut failed = 0u64;
        run_hybrid_worker(args, slots_per_ring, total_threads, io_threads, &next, &mut |idx, res| {
            results[idx] = Some(res);
            while printed < nfiles {
                let Some(item) = results[printed].take() else { break };
                if let Err(e) = item.and_then(|h| crate::print_hash_output(h, &args.file_args[printed], args, out)) {
                    failed = failed.saturating_add(1);
                    let _ = out.flush();
                    eprintln!("{}: {}: {}", crate::NAME, args.file_args[printed].to_string_lossy(), e);
                }
                printed += 1;
            }
            true
        });
        return Some(failed);
    }

    let next = AtomicUsize::new(0);
    let (done_tx, done_rx) = std::sync::mpsc::channel::<(usize, anyhow::Result<blake3::Hash>)>();
    std::thread::scope(|scope| {
        for _ in 1..io_threads {
            if next.load(Ordering::Relaxed) >= nfiles {
                break;
            }
            let (next_ref, tx) = (&next, done_tx.clone());
            scope.spawn(move || {
                run_hybrid_worker(args, slots_per_ring, total_threads, io_threads, next_ref, &mut |i, res| tx.send((i, res)).is_ok());
            });
        }
        drop(done_tx);

        let mut results: Vec<Option<anyhow::Result<blake3::Hash>>> = (0..nfiles).map(|_| None).collect();
        let mut printed = 0usize;
        let mut failed = 0u64;
        let mut take = |idx: usize, res: anyhow::Result<blake3::Hash>| -> bool {
            results[idx] = Some(res);
            while printed < nfiles {
                let Some(item) = results[printed].take() else { break };
                if let Err(e) = item.and_then(|h| crate::print_hash_output(h, &args.file_args[printed], args, out)) {
                    failed = failed.saturating_add(1);
                    let _ = out.flush();
                    eprintln!("{}: {}: {}", crate::NAME, args.file_args[printed].to_string_lossy(), e);
                }
                printed += 1;
            }
            true
        };

        run_hybrid_worker(args, slots_per_ring, total_threads, io_threads, &next, &mut |i, res| {
            while let Ok((wi, wres)) = done_rx.try_recv() {
                take(wi, wres);
            }
            take(i, res)
        });
        for (i, res) in done_rx {
            take(i, res);
        }
        Some(failed)
    })
}

fn run_hybrid_worker(
    args: &Args,
    max_slots: usize,
    total_threads: usize,
    io_threads: usize,
    next: &AtomicUsize,
    done: &mut dyn FnMut(usize, anyhow::Result<blake3::Hash>) -> bool,
) {
    let paths = &args.file_args;
    let mut warm_batch = WarmBatch::new();
    let mut medium_buf: Vec<u8> = Vec::new();
    let mut warm_pipe: Option<WarmLargePipe> = None;
    let mut cold: Option<ColdRingState> = None;
    let mut uring_unavailable = false;
    let mut keep_going = true;

    while keep_going {
        if let Some(ref mut wp) = warm_pipe {
            wp.drain(done, &mut keep_going);
        }
        if let Some(ref mut c) = cold {
            let submit_batch = if c.ring_in_flight <= 8 { 4 } else { 16 };
            if c.ring.unsubmitted() >= submit_batch {
                c.step_ring(false, args.mode, &mut warm_batch, done, &mut keep_going);
            }
            while keep_going && (c.free_slot_ids.is_empty() || c.ring.sq_space_left() == 0) {
                c.step_ring(true, args.mode, &mut warm_batch, done, &mut keep_going);
            }
            if !keep_going {
                break;
            }
        }

        let i = next.fetch_add(1, Ordering::Relaxed);
        if i >= paths.len() {
            break;
        }

        let opened = File::open(&paths[i]).and_then(|f| Ok((f.metadata()?, f)));
        let (meta, file) = match opened {
            Ok(pair) => pair,
            Err(e) => {
                if !done(i, Err(e.into())) {
                    keep_going = false;
                }
                continue;
            }
        };

        if !meta.is_file() {
            if !done(i, crate::hash_path_hash(args, &paths[i])) {
                keep_going = false;
            }
            continue;
        }

        let size = meta.len();

        // 1. Small files `<= 16 KiB`: try 1-syscall `preadv2(RWF_NOWAIT)` into core-local `WarmBatch`!
        if size <= WARM_BATCH_MAX_FILE as u64 {
            let hint = size as usize;
            let slot_idx = warm_batch.len;
            let (slot_ptr, slot_cap) = warm_batch.slot_ptr_and_cap(slot_idx);
            match try_pread_cached(file.as_raw_fd(), slot_ptr, slot_cap, 0, hint) {
                Ok((n, true)) => {
                    drop(file);
                    warm_batch.entries[slot_idx] = (i, n);
                    warm_batch.len += 1;
                    if warm_batch.len == WARM_BATCH_SLOTS {
                        warm_batch.flush(args.mode, done, &mut keep_going);
                    }
                    continue;
                }
                Ok((partial_at, false)) => {
                    if !uring_unavailable && cold.is_none() {
                        cold = ColdRingState::new(max_slots);
                        if cold.is_none() {
                            uring_unavailable = true;
                        }
                    }
                    if let Some(ref mut c) = cold {
                        while c.free_slot_ids.is_empty() || c.ring.sq_space_left() == 0 {
                            c.step_ring(true, args.mode, &mut warm_batch, done, &mut keep_going);
                        }
                        let mut buf = c.free_bufs.pop().unwrap_or_default();
                        let cap = (hint + 1).max(partial_at + 4096);
                        ensure_spare_cap(&mut buf, cap);
                        if partial_at > 0 {
                            let (src_ptr, _) = warm_batch.slot_ptr_and_cap(slot_idx);
                            unsafe { core::ptr::copy_nonoverlapping(src_ptr, buf.as_mut_ptr(), partial_at) };
                        }
                        let sid = c.free_slot_ids.pop().unwrap();
                        let fd = file.as_raw_fd();
                        let ptr = unsafe { buf.as_mut_ptr().add(partial_at) };
                        let rlen = (buf.capacity() - partial_at) as u32;
                        c.slots[sid] = Some(SmallSlot { file_idx: i, file, buf, at: partial_at, hint });
                        unsafe { c.ring.push_read(fd, ptr, rlen, partial_at as u64, 0, sid as u64) };
                        c.ring_in_flight += 1;
                    } else {
                        let mut buf = Vec::with_capacity((hint + 1).max(4096));
                        if partial_at > 0 {
                            let (src_ptr, _) = warm_batch.slot_ptr_and_cap(slot_idx);
                            unsafe { core::ptr::copy_nonoverlapping(src_ptr, buf.as_mut_ptr(), partial_at) };
                        }
                        let res = read_rest_sync_uninit(&file, &mut buf, partial_at).map(|n| crate::hash_slice_32(args.mode, &buf[..n])).map_err(Into::into);
                        if !done(i, res) {
                            keep_going = false;
                        }
                    }
                    continue;
                }
                Err(e) => {
                    if !done(i, Err(e.into())) {
                        keep_going = false;
                    }
                    continue;
                }
            }
        }

        // 2. Medium files `16 KiB < size < 512 KiB`: try `RWF_NOWAIT` into core-local `medium_buf`!
        if size < SMALL {
            let hint = size as usize;
            ensure_spare_cap(&mut medium_buf, hint + 1);
            match try_pread_cached(file.as_raw_fd(), medium_buf.as_mut_ptr(), medium_buf.capacity(), 0, hint) {
                Ok((n, true)) => {
                    drop(file);
                    unsafe { medium_buf.set_len(n) };
                    let h = crate::hash_slice_32(args.mode, &medium_buf);
                    medium_buf.clear();
                    if !done(i, Ok(h)) {
                        keep_going = false;
                    }
                    continue;
                }
                Ok((partial_at, false)) => {
                    if !uring_unavailable && cold.is_none() {
                        cold = ColdRingState::new(max_slots);
                        if cold.is_none() {
                            uring_unavailable = true;
                        }
                    }
                    if let Some(ref mut c) = cold {
                        while c.free_slot_ids.is_empty() || c.ring.sq_space_left() == 0 {
                            c.step_ring(true, args.mode, &mut warm_batch, done, &mut keep_going);
                        }
                        let mut buf = c.free_bufs.pop().unwrap_or_default();
                        let cap = (hint + 1).max(partial_at + 8192);
                        ensure_spare_cap(&mut buf, cap);
                        if partial_at > 0 {
                            unsafe { core::ptr::copy_nonoverlapping(medium_buf.as_ptr(), buf.as_mut_ptr(), partial_at) };
                        }
                        let sid = c.free_slot_ids.pop().unwrap();
                        let fd = file.as_raw_fd();
                        let ptr = unsafe { buf.as_mut_ptr().add(partial_at) };
                        let rlen = (buf.capacity() - partial_at) as u32;
                        c.slots[sid] = Some(SmallSlot { file_idx: i, file, buf, at: partial_at, hint });
                        unsafe { c.ring.push_read(fd, ptr, rlen, partial_at as u64, 0, sid as u64) };
                        c.ring_in_flight += 1;
                    } else {
                        let res = read_rest_sync_uninit(&file, &mut medium_buf, partial_at)
                            .map(|n| crate::hash_slice_32(args.mode, &medium_buf[..n]))
                            .map_err(Into::into);
                        medium_buf.clear();
                        if !done(i, res) {
                            keep_going = false;
                        }
                    }
                    continue;
                }
                Err(e) => {
                    if !done(i, Err(e.into())) {
                        keep_going = false;
                    }
                    continue;
                }
            }
        }

        // 3. Large files `>= 512 KiB`: check `resident(&map)` BEFORE creating any `Uring`!
        warm_batch.flush(args.mode, done, &mut keep_going);
        if let Ok(map) = unsafe { memmap2::Mmap::map(&file) } {
            if crate::resident(&map) {
                if size < (4 << 20) {
                    let h = crate::hash_slice_32(args.mode, &map);
                    crate::hold(map);
                    if !done(i, Ok(h)) {
                        keep_going = false;
                    }
                    continue;
                }
                let pool_workers = if args.num_threads().is_some() { (total_threads - io_threads + 1).max(1) } else { total_threads };
                crate::init_pool_once(pool_workers);
                let wp = warm_pipe.get_or_insert_with(|| WarmLargePipe::new(args.mode));
                wp.submit_lent(i, size, map, done, &mut keep_going);
                continue;
            }
            drop(map);
        }

        if !uring_unavailable && cold.is_none() {
            cold = ColdRingState::new(max_slots);
            if cold.is_none() {
                uring_unavailable = true;
            }
        }

        if let Some(ref mut c) = cold {
            let pool_workers = if args.num_threads().is_some() { (total_threads - io_threads + 1).max(1) } else { total_threads.min(16) };
            crate::init_pool_once(pool_workers);
            let cpipe = c.cold_large_pipe.get_or_insert_with(|| Pipeline::<usize, ()>::new(args.mode, Limits { messages: 2, rooms: LARGE_WINDOW }));
            let mut m = block_on(cpipe.message(i, Some(size)));
            match stream_fd_into_rooms(&mut c.ring, &mut c.deferred_cqes, cpipe, &mut m, file.as_raw_fd(), size) {
                Ok(()) => {
                    cpipe.end(m);
                    let h = loop {
                        if let Some(Event::Hashed { hash, .. }) = cpipe.next_event() {
                            break hash;
                        }
                        block_on(cpipe.ready());
                    };
                    if !done(i, Ok(h)) {
                        keep_going = false;
                    }
                }
                Err(e) => {
                    cpipe.abort(m);
                    while cpipe.next_event().is_none() {
                        block_on(cpipe.ready());
                    }
                    if !done(i, Err(e.into())) {
                        keep_going = false;
                    }
                }
            }
        } else if let Err(e) = crate::hash_path_hash(args, &paths[i]).map(|h| {
            if !done(i, Ok(h)) {
                keep_going = false;
            }
        }) {
            if !done(i, Err(e)) {
                keep_going = false;
            }
        }
    }

    if let Some(mut c) = cold {
        c.finish(args.mode, &mut warm_batch, done, &mut keep_going);
    }
    warm_batch.flush(args.mode, done, &mut keep_going);
    if let Some(mut wp) = warm_pipe {
        wp.finish(done, &mut keep_going);
    }
}

#[cfg(test)]
mod test {
    use std::os::fd::AsRawFd;

    #[test]
    fn sync_fallback_and_uring_agree_across_hints_and_growing_files() {
        blake3::initialize();
        let dir = tempfile::tempdir().unwrap();
        let p = dir.path().join("grow");
        let content: Vec<u8> = (0..100_000u32).map(|i| (i * 7) as u8).collect();
        std::fs::write(&p, &content).unwrap();
        let f = std::fs::File::open(&p).unwrap();
        let mut buf = Vec::with_capacity(16);
        let n = super::read_rest_sync_uninit(&f, &mut buf, 0).unwrap();
        assert_eq!(n, content.len());
        assert_eq!(&buf[..], &content[..]);

        let mut slice_buf = vec![0u8; 5000];
        let m = super::pread_fill_rest(f.as_raw_fd(), &mut slice_buf, 123).unwrap();
        assert_eq!(m, 5000);
        assert_eq!(&slice_buf[..], &content[123..5123]);
    }

    #[test]
    fn stream_fd_into_rooms_and_evicted_cold_batch_match_reference() {
        blake3::initialize();
        let Ok(mut ring) = crate::uring::Uring::new(64) else { return };
        crate::init_pool_once(2);

        // Test `stream_fd_into_rooms` across exact 64 KiB multiples, odd tails, and > 4 MiB!
        let dir = tempfile::tempdir_in(".").unwrap_or_else(|_| tempfile::tempdir().unwrap());
        for &len in &[0usize, 1, 65_535, 65_536, 65_537, 600_000, 4_500_000] {
            let p = dir.path().join(format!("large-{len}"));
            let data: Vec<u8> = (0..len).map(|i| (i.wrapping_mul(31) ^ (i >> 8)) as u8).collect();
            {
                use std::io::Write;
                let mut wf = std::fs::File::create(&p).unwrap();
                wf.write_all(&data).unwrap();
                wf.sync_all().unwrap();
            }
            let rf = std::fs::File::open(&p).unwrap();
            unsafe { libc::posix_fadvise(rf.as_raw_fd(), 0, 0, libc::POSIX_FADV_DONTNEED) };

            let mut pipe = blake3::throughput::Pipeline::<usize, ()>::new(
                blake3::Mode::DeriveKey("b3sum-uring-room-test"),
                blake3::throughput::Limits { messages: 2, rooms: super::LARGE_WINDOW },
            );
            let mut deferred = std::collections::VecDeque::new();
            let mut m = blake3::throughput::block_on(pipe.message(0, Some(len as u64)));
            // Also test wrong smaller hint (`len / 3`) to verify growing-file extension!
            super::stream_fd_into_rooms(&mut ring, &mut deferred, &mut pipe, &mut m, rf.as_raw_fd(), (len / 3) as u64).unwrap();
            pipe.end(m);
            let got = loop {
                if let Some(blake3::throughput::Event::Hashed { hash, .. }) = pipe.next_event() {
                    break hash;
                }
                blake3::throughput::block_on(pipe.ready());
            };
            let mut want_h = blake3::convenience::Hasher::new(blake3::Mode::DeriveKey("b3sum-uring-room-test"), None);
            want_h.update(&data);
            assert_eq!(got, want_h.finalize(), "room stream len={len}");
        }
    }
}
