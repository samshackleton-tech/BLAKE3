#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <unistd.h>

void call_kernel(void *f, const uint64_t *args, uint64_t *after);
extern uint64_t call_kernel_values[6];

#define MAX_BUF (1u << 18)   /* 256 KiB per buffer + 4 KiB PROT_NONE guard page */
#define PAGE 4096u

static uint8_t *g_code = NULL;
static size_t g_code_map = 0;
static uint8_t *g_arena[6] = {0};

int init_runner(const uint8_t *image, size_t img_len) {
    if (g_code) munmap(g_code, g_code_map);
    g_code_map = ((img_len + PAGE - 1) / PAGE) * PAGE;
    if (!g_code_map) g_code_map = PAGE;
    g_code = mmap(NULL, g_code_map, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (g_code == MAP_FAILED) { g_code = NULL; return -1; }
    memcpy(g_code, image, img_len);
    if (mprotect(g_code, g_code_map, PROT_READ | PROT_EXEC) != 0) return -2;
    for (int i = 0; i < 6; i++) {
        if (!g_arena[i]) {
            uint8_t *p = mmap(NULL, MAX_BUF + PAGE, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
            if (p == MAP_FAILED) return -3;
            if (mprotect(p + MAX_BUF, PAGE, PROT_NONE) != 0) return -4;
            g_arena[i] = p;
        }
    }
    return 0;
}

/* kind: 0 = number/byte/any, 1 = readonly buf, 2 = writable buf (size in len[i])
   returns: 0 = ok, 1 = callee-saved reg clobbered, 2 = rsp moved, 3 = write before buf,
            4 = child crashed/timed out (status in *sig_out), 5 = buf too big */
static int exec_in_proc(size_t entry_off, int n_args, const int *kinds, const uint64_t *vals,
                        const uint8_t * const *in_ptrs, const size_t *lens,
                        uint8_t * const *out_ptrs, uint64_t *rax_out) {
    uint64_t args[6] = {0}, after[8] = {0};
    uint8_t *ptrs[6] = {0};
    for (int i = 0; i < n_args && i < 6; i++) {
        if (kinds[i] == 0) {
            args[i] = vals[i];
        } else {
            if (lens[i] > MAX_BUF) return 5;
            uint8_t *a = g_arena[i];
            uint8_t *p = a + MAX_BUF - lens[i];
            memset(a, 0xA5, MAX_BUF - lens[i]);
            if (kinds[i] == 1) {
                if (lens[i] && in_ptrs[i]) memcpy(p, in_ptrs[i], lens[i]);
            } else {
                if (lens[i]) memset(p, 0x5A, lens[i]);
            }
            ptrs[i] = p;
            args[i] = (uint64_t)(uintptr_t)p;
        }
    }
    call_kernel(g_code + entry_off, args, after);
    for (int r = 0; r < 6; r++) {
        if (after[r] != call_kernel_values[r]) return 1;
    }
    if (after[6] != 0) return 2;
    for (int i = 0; i < n_args && i < 6; i++) {
        if (kinds[i] == 2) {
            uint8_t *a = g_arena[i];
            size_t prefix = MAX_BUF - lens[i];
            for (size_t k = 0; k < prefix; k++) {
                if (a[k] != 0xA5) return 3;
            }
            if (lens[i] && out_ptrs[i]) memcpy(out_ptrs[i], ptrs[i], lens[i]);
        }
    }
    *rax_out = after[7];
    return 0;
}

int run_forked(size_t entry_off, int n_args, const int *kinds, const uint64_t *vals,
               const uint8_t * const *in_ptrs, const size_t *lens,
               uint8_t * const *out_ptrs, uint64_t *rax_out, int *sig_out, unsigned timeout_sec) {
    int pfd[2];
    if (pipe(pfd) != 0) return -1;
    pid_t pid = fork();
    if (pid < 0) { close(pfd[0]); close(pfd[1]); return -1; }
    if (pid == 0) {
        close(pfd[0]);
        if (timeout_sec) alarm(timeout_sec);
        uint64_t rax = 0;
        uint8_t *tmp_out[6] = {0};
        for (int i = 0; i < n_args && i < 6; i++) {
            if (kinds[i] == 2 && lens[i]) tmp_out[i] = malloc(lens[i]);
        }
        int rc = exec_in_proc(entry_off, n_args, kinds, vals, in_ptrs, lens, tmp_out, &rax);
        ssize_t w;
        w = write(pfd[1], &rc, sizeof(rc));
        w = write(pfd[1], &rax, sizeof(rax));
        if (rc == 0) {
            for (int i = 0; i < n_args && i < 6; i++) {
                if (kinds[i] == 2 && lens[i]) w = write(pfd[1], tmp_out[i], lens[i]);
            }
        }
        (void)w;
        _exit(0);
    }
    close(pfd[1]);
    int rc = 4;
    uint64_t rax = 0;
    ssize_t n1 = read(pfd[0], &rc, sizeof(rc));
    ssize_t n2 = read(pfd[0], &rax, sizeof(rax));
    if (n1 == sizeof(rc) && n2 == sizeof(rax) && rc == 0) {
        for (int i = 0; i < n_args && i < 6; i++) {
            if (kinds[i] == 2 && lens[i]) {
                size_t got = 0;
                while (got < lens[i]) {
                    ssize_t m = read(pfd[0], out_ptrs[i] + got, lens[i] - got);
                    if (m <= 0) { rc = 4; break; }
                    got += (size_t)m;
                }
            }
        }
    } else if (n1 != sizeof(rc)) {
        rc = 4;
    }
    close(pfd[0]);
    int st = 0;
    waitpid(pid, &st, 0);
    if (rc == 4) {
        *sig_out = WIFSIGNALED(st) ? WTERMSIG(st) : (WIFEXITED(st) ? WEXITSTATUS(st) : -1);
        return 4;
    }
    *rax_out = rax;
    *sig_out = 0;
    return rc;
}

/* Fast path: run directly in-process when caller already forked a batch worker */
int run_direct(size_t entry_off, int n_args, const int *kinds, const uint64_t *vals,
               const uint8_t * const *in_ptrs, const size_t *lens,
               uint8_t * const *out_ptrs, uint64_t *rax_out) {
    return exec_in_proc(entry_off, n_args, kinds, vals, in_ptrs, lens, out_ptrs, rax_out);
}
