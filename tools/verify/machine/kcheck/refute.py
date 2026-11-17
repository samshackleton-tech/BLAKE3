#!/usr/bin/env python3
"""refute: "false, and here is the input". A contract of a specification is worked out on numbers beside the
binary's own code run on this machine's processor, on inputs made for the purpose.

    python3 refute.py BINARY [SPEC] [--symbol NAME] [--cases N] [--seed S]

For each function of BINARY that SPEC (or the specification the binary carries) has a public contract for:
inputs that meet `requires` are made (edges first: lengths 0, 1, the numbers the specification itself writes
and their neighbours; then random ones), the code is run on each in a child process, and what it did is
compared with what the contract says. It says FALSE, with the input, where the code

  - crashes, or runs for more than two seconds (it read or wrote past what it was given: every buffer ends where
    a page that faults begins; or it does not return);
  - writes before a buffer it may write, or does not give back a register a callee keeps, or the stack pointer;
  - returns another number than the contract's, or leaves other bytes than the contract's;
  - does not meet an `ensures` condition.

"Not refuted" is no proof: it says only that these inputs found nothing. A FALSE is a fact one can check by
hand: the input is printed. This is a prover's tool (nothing a verifier says rests on it): it answers the
question a refusal leaves open, whether the thing not shown is false or only not shown.

It runs x86-64 code, so it needs an x86-64 Linux machine and a C compiler (`available()` says)."""
import ctypes, hashlib, os, platform, random, shutil, subprocess, sys, tempfile, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kdecode, kfn, ode, check_binary

LIB = None


def available():
    return platform.system() == "Linux" and platform.machine() in ("x86_64", "AMD64") and shutil.which("cc") is not None


def library():
    """The runner (refute_run.c, kflip_thunk.S), built once into the temporary folder."""
    global LIB
    if LIB is not None: return LIB
    if not available(): raise RuntimeError("the refuter runs the binary's code: it needs an x86-64 Linux machine and a C compiler")
    with open(os.path.join(HERE, "refute_run.c"), "rb") as f: digest = hashlib.sha256(f.read()).hexdigest()[:16]
    folder = os.path.join(tempfile.gettempdir(), f"ode-refute-{os.getuid()}-{digest}")
    so = os.path.join(folder, "librefute.so")
    if not os.path.exists(so):
        os.makedirs(folder, mode=0o700, exist_ok=True)
        subprocess.run(["cc", "-O2", "-shared", "-fPIC", "-Wl,-Bsymbolic", "-o", so + ".tmp", os.path.join(HERE, "refute_run.c"), os.path.join(HERE, "kflip_thunk.S")], check=True)
        os.replace(so + ".tmp", so)
    LIB = ctypes.CDLL(so)
    LIB.init_runner.argtypes = [ctypes.c_char_p, ctypes.c_size_t]
    LIB.init_runner.restype = ctypes.c_int
    LIB.run_forked.argtypes = [
        ctypes.c_size_t, ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_uint64),
        ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_size_t), ctypes.POINTER(ctypes.c_void_p),
        ctypes.POINTER(ctypes.c_uint64), ctypes.POINTER(ctypes.c_int), ctypes.c_uint,
    ]
    LIB.run_forked.restype = ctypes.c_int
    return LIB

NO = (1 << 64) - 1
N = ode.Numbers()


def load_spec_and_offsets(bin_path, spec_path=None):
    e = kdecode.Elf(bin_path)
    if not kdecode.settled(e):
        raise SystemExit(f"{bin_path}: has relocations for a linker to fill in")
    s = kdecode.Settled(e)
    proof = check_binary.carried(e.bytes_of(".ode.proof")) if ".ode.proof" in e.index else None
    inner = ""
    if spec_path is None:
        if proof is None or "specification" not in proof["files"]:
            raise SystemExit(f"{bin_path}: no specification given and binary carries none")
        text = proof["files"]["specification"].decode()
    else:
        with open(spec_path) as f: text = f.read()
    if proof is not None:
        for nm, body in sorted(proof["files"].items()):
            if nm.endswith((".inner", ".lemmas")) or nm == "proofs/inner.spec":
                inner += "\n" + body.decode()
    spec = ode.with_proof(text, inner) if inner else ode.Spec(text)
    public = set(ode.Spec(text).contracts)
    at = dict(s.at)
    if proof is not None and "code" in proof and any(nm not in at for nm in proof["at"]):
        # A file without names: the proof's places are places in the code it is of, and that code is found in
        # the file by its bytes. (Until November 16, 2026 they were taken as places in the file: in a linked
        # file stripped of its names the code was entered somewhere else, and a true contract was called FALSE.)
        import kshow
        size, digest, begins = proof["code"]
        hit = next((k for k in range(0, len(s.image) - size + 1, 16) if s.image[k:k + len(begins)] == begins and kshow.b3(s.image[k:k + size]) == digest), None)
        if hit is not None:
            for nm, off in proof["at"].items():
                if nm not in at: at[nm] = hit + off
    return s, spec, public, at


def expr_refs(e):
    out = set()
    if isinstance(e, tuple):
        if e[0] == "name": out.add(e[1])
        for x in e[1:]: out |= expr_refs(x)
    elif isinstance(e, list):
        for x in e: out |= expr_refs(x)
    return out


def spec_bytes(spec):
    """Bytes hinted by numbers in the specification (k, k-1, k+1 for small integers) plus UTF-8/LZ4 edges."""
    vals = {0, 1, 2, 3, 4, 15, 16, 31, 63, 64, 127, 128, 191, 192, 223, 224, 239, 240, 244, 255}
    def walk(x):
        if isinstance(x, tuple):
            if x[0] == "num" and isinstance(x[1], int):
                for d in (-1, 0, 1):
                    if 0 <= x[1] + d < 256: vals.add(x[1] + d)
            for y in x[1:]: walk(y)
        elif isinstance(x, list):
            for y in x: walk(y)
    for _, body in spec.fns.values(): walk(body)
    for _, _, _, f, nxt in spec.seqs.values(): walk(f); walk(nxt)
    return sorted(vals)


def gen_bytes(rng, n, mode, edge=None):
    if n == 0: return []
    if mode == 0: return [0] * n
    if mode == 1: return [255] * n
    if mode == 2: return [rng.randrange(256) for _ in range(n)]
    if mode == 3:
        alpha = rng.choice([2, 3, 8, 64])
        return [(rng.randrange(alpha) * 37) & 255 for _ in range(n)]
    if mode == 4:
        pool = edge or [0x00, 0x41, 0x7F, 0x80, 0xBF, 0xC2, 0xDF, 0xE0, 0xA0, 0xF0, 0x90, 0xF4, 0x8F, 0xFF]
        return [rng.choice(pool) if rng.random() < 0.85 else rng.randrange(256) for _ in range(n)]
    # structured LZ4-ish token stream
    out, dec = [], 0
    while len(out) < n:
        lit = rng.choice([0, 1, 2, 3, 14, 15, 20])
        m = rng.choice([0, 1, 5, 14, 15])
        if len(out) + 1 + lit >= n:
            lit = max(0, n - len(out) - 1)
            out.append((min(lit, 15) << 4))
            out.extend(rng.randrange(256) for _ in range(lit))
            break
        out.append((min(lit, 15) << 4) | min(m, 15))
        if lit >= 15:
            r = lit - 15
            while r >= 255 and len(out) < n: out.append(255); r -= 255
            if len(out) < n: out.append(r)
        take = min(lit, n - len(out))
        out.extend(rng.randrange(256) for _ in range(take))
        dec += take
        if len(out) >= n: break
        if len(out) + 2 <= n:
            off = rng.randint(1, max(1, dec)) if dec else 1
            out.append(off & 255); out.append((off >> 8) & 255)
            dec += m + 4
    return out[:n]


def sample_inputs(spec, sym, c, count, seed):
    rng = random.Random(seed)
    args = c["args"]
    kinds = {nm: k for nm, k in args}
    writes = set(c["spoils"]) | {leaf["name"] for leaf in c["leaves"]}
    writes.discard(c["returns"][1] if c["returns"] and c["returns"][0] == "name" else None)

    # collect lower/upper expressions from requires
    num_args = [nm for nm, k in args if k in ("number", "byte", "any")]
    buf_args = [nm for nm, k in args if k not in ("number", "byte", "any")]
    len_vars = {kfn.bytes_kind(k) for _, k in args if isinstance(kfn.bytes_kind(k), str)}
    edge = spec_bytes(spec)

    def try_make(case):
        env = {}
        # order number args: non-derived / small bounds first, then dependent ones (like cap)
        deps = {nm: set() for nm in num_args}
        bounds = {nm: [] for nm in num_args}
        for ask in c["asks"]:
            if ask[0] == "bin" and ask[1] in (">=", "<=", ">", "<", "=="):
                op, a, b = ask[1], ask[2], ask[3]
                if a[0] == "name" and a[1] in deps and a[1] not in expr_refs(b):
                    deps[a[1]] |= (expr_refs(b) & set(num_args))
                    bounds[a[1]].append((op, b))
                elif b[0] == "name" and b[1] in deps and b[1] not in expr_refs(a):
                    flip = {">=": "<=", "<=": ">=", ">": "<", "<": ">", "==": "=="}[op]
                    deps[b[1]] |= (expr_refs(a) & set(num_args))
                    bounds[b[1]].append((flip, a))
        order, rem = [], sorted(num_args, key=lambda x: x == "cap")
        while rem:
            nxt = next((x for x in rem if not (deps[x] & set(rem))), rem[0])
            order.append(nxt); rem.remove(nxt)

        edge_nums = [0, 1, 2, 3, 4, 5, 7, 8, 15, 16, 31, 32, 63, 64, 65, 127, 128, 255, 256, 511, 512, 1023, 1024, 1025, 2048, 5552, 65535]
        for nm in order:
            k = kinds[nm]
            if k == "byte":
                pool = [0, 1, 2, 4, 8, 16, 32, 64, 128, 255]
                env[nm] = pool[case % len(pool)] if case < 30 else rng.randrange(256)
                continue
            if k == "any":
                pool = [0, 1, 2, 3, 4, 5, 6, NO]
                env[nm] = pool[case % len(pool)] if case < 24 else rng.choice([0, 5, rng.randrange(1 << 64)])
                continue
            # number
            lo, hi = 0, NO
            for op, e in bounds[nm]:
                try: val = spec.eval(N, e, env)
                except Exception: continue
                if isinstance(val, int):
                    if op == ">=": lo = max(lo, val)
                    elif op == ">": lo = max(lo, val + 1)
                    elif op == "<=": hi = min(hi, val)
                    elif op == "<": hi = min(hi, val - 1)
                    elif op == "==": lo = hi = val
            if nm in len_vars:
                hi = min(hi, 16384 if "blake3" in sym or "b3l_" in sym else 8192)
                if lo > hi: return None
                if nm == "cap" and "n" in env:
                    m = env["n"]
                    picks = [0, m, m + m // 255 + 15, m + m // 255 + 16, m + 32, 4 * ((m + 2) // 3), rng.randint(lo, hi)]
                    v = picks[case % len(picks)] if case < 25 else rng.randint(lo, min(hi, max(lo + 32, m + 2048)))
                    env[nm] = min(hi, max(lo, v))
                elif case < 25 and lo <= 1 <= hi: env[nm] = 1 if case < 15 else min(hi, max(lo, case % 5))
                elif case < len(edge_nums) and lo <= edge_nums[case] <= hi: env[nm] = edge_nums[case]
                elif lo == hi:
                    env[nm] = lo
                else:
                    env[nm] = rng.randint(lo, min(hi, lo + (200 if case % 3 else 4000)))
            else:
                if lo > hi: return None
                if lo == hi: env[nm] = lo
                elif case % 13 == 0 and hi <= (1 << 64) - 1: env[nm] = min(hi, lo + rng.choice([0, 1, 2, 3, 16, 100]))
                elif hi < (1 << 20): env[nm] = rng.randint(lo, hi)
                else: env[nm] = min(hi, lo + rng.choice([0, 1, 2, 15, 16, 127, 128, 255, 1024, rng.randrange(1 << 20), rng.randrange(1 << 64)]))
                if nm == "cap" and env[nm] > 131072 and any(b == "out" for b in buf_args):
                    env[nm] = min(hi, max(lo, rng.randint(lo, max(lo, 4096))))
        # check asks
        for ask in c["asks"]:
            try:
                if spec.eval(N, ask, env) is not True: return None
            except Exception: return None
        # check `needs` feature limits for this host (on x86 workhorse sse41 & avx512 exist, but plat==5 check passes)
        # fill read-only buffers
        ro_bytes = {}
        buf_sizes = {}
        for nm in buf_args:
            bk = kfn.bytes_kind(kinds[nm])
            sz = env[bk] if isinstance(bk, str) else bk
            if sz > 131072: return None
            buf_sizes[nm] = sz
            if nm not in writes:
                if sz == 1 and one_i[0] < len(edge): b = [edge[one_i[0]]]; one_i[0] += 1
                else: b = gen_bytes(rng, sz, case % 6, edge)
                ro_bytes[nm] = b
                env[nm] = b
        return env, buf_sizes, ro_bytes

    out, attempt, one_i = [], 0, [0]
    while len(out) < count and attempt < count * 20:
        r = try_make(len(out) if attempt < count else attempt)
        attempt += 1
        if r is not None: out.append(r)
    if "lz4" in spec.fns and "adler32" in spec.fns and "be32" in spec.fns:
        for text in ([], [65], [65, 65, 65, 65, 65], [i % 13 for i in range(40)]):
            lit = len(text); blk = ([lit << 4] + text) if lit < 15 else ([0xF0, lit - 15] + text)
            if "be32" in spec.fns:
                s = spec.call(N, "adler32", text)
                bs = blk + [(s >> 24) & 255, (s >> 16) & 255, (s >> 8) & 255, s & 255]
                for cap in (len(text), len(text) + 10, max(0, len(text) - 1)):
                    env = {"n": len(bs), "cap": cap, "input": bs}
                    if all(nm in env for nm, _ in args if nm not in writes) and all(spec.eval(N, a, env) is True for a in c["asks"]):
                        out.insert(0, (env, {"out": cap, "input": len(bs)}, {"input": bs}))
    return out[:count]


def format_case(c, env, buf_sizes, ro_bytes):
    parts = []
    for nm, k in c["args"]:
        if k in ("number", "byte", "any"): parts.append(f"{nm}={env[nm]}")
        elif nm in ro_bytes:
            bs = bytes(ro_bytes[nm])
            h = bs[:32].hex() + ("..." if len(bs) > 32 else "")
            parts.append(f"{nm}[{len(bs)}]={h}")
        else:
            parts.append(f"{nm}(out, cap={buf_sizes[nm]})")
    return ", ".join(parts)


def check_one(spec, c, env, buf_sizes, ro_bytes, rax, out_bufs):
    res_name = c["returns"][1] if c["returns"] is not None and c["returns"][0] == "name" and c["returns"][1] not in env else None
    e2 = dict(env)
    for nm, b in out_bufs.items(): e2[nm] = list(b)
    if res_name is not None: e2[res_name] = rax
    # check returns
    if c["returns"] is not None and res_name is None:
        try: want = spec.eval(N, c["returns"], e2)
        except ode.Fails: return None
        except ode.Err as err: return f"specification error while evaluating returns: {err}"
        if rax != want:
            return f"returned {rax} (0x{rax:x}), specification says {want} (0x{want:x})"
    # check leaves
    for leaf in c["leaves"]:
        if leaf["cond"] is not None:
            try:
                if spec.eval(N, leaf["cond"], e2) is not True: continue
            except ode.Fails: continue
            except ode.Err as err: return f"specification error while evaluating guard: {err}"
        try: want = spec.eval(N, leaf["expr"], e2)
        except ode.Fails: continue
        except ode.Err as err: return f"specification error while evaluating ensures: {err}"
        if leaf["name"] == res_name:
            if rax != want: return f"returned {rax}, specification says {want}"
            continue
        got_all = list(out_bufs[leaf["name"]])
        if leaf["part"] is not None:
            a = spec.eval(N, leaf["part"][0], e2)
            b = buf_sizes[leaf["name"]] if leaf["part"][1] == ("num", None) else spec.eval(N, leaf["part"][1], e2)
            got = got_all[a:b]
        else:
            got = got_all
        if want and isinstance(want[0], ode.Word): want = N.bytes_of(want)
        if got != want:
            diff = next((i for i, (g, w) in enumerate(zip(got, want)) if g != w), min(len(got), len(want)))
            return f"{leaf['name']} has {len(got)} bytes, specification says {len(want)} (first mismatch at byte {diff}: got {got[diff] if diff < len(got) else 'EOF'}, want {want[diff] if diff < len(want) else 'EOF'})"
    # check conditions
    for cond, guard in c["conditions"]:
        if guard is not None:
            try:
                if spec.eval(N, guard, e2) is not True: continue
            except ode.Fails: continue
            except ode.Err as err: return f"specification error while evaluating guard: {err}"
        try:
            if spec.eval(N, cond, e2) is not True:
                return f"ensures condition failed (with {res_name}={rax})" if res_name else "ensures condition failed"
        except ode.Fails: continue
        except ode.Err as err: return f"specification error while evaluating condition: {err}"
    return None


def refute_symbol(s, spec, sym, entry_off, cases, seed):
    c = spec.contracts[sym]
    if len(c["args"]) > 6: raise SystemExit(f"{sym}: more than 6 args")
    writes = set(c["spoils"]) | {leaf["name"] for leaf in c["leaves"]}
    writes.discard(c["returns"][1] if c["returns"] and c["returns"][0] == "name" else None)

    n_args = len(c["args"])
    kinds_arr = (ctypes.c_int * 6)()
    vals_arr = (ctypes.c_uint64 * 6)()
    in_ptrs = (ctypes.c_void_p * 6)()
    lens_arr = (ctypes.c_size_t * 6)()
    out_ptrs = (ctypes.c_void_p * 6)()
    rax_out = ctypes.c_uint64()
    sig_out = ctypes.c_int()

    for i, (nm, k) in enumerate(c["args"]):
        if k in ("number", "byte", "any"): kinds_arr[i] = 0
        elif nm in writes: kinds_arr[i] = 2
        else: kinds_arr[i] = 1

    samples = sample_inputs(spec, sym, c, cases, seed)
    t0 = time.time()
    for idx, (env, buf_sizes, ro_bytes) in enumerate(samples):
        in_keep, out_keep = [], {}
        for i, (nm, k) in enumerate(c["args"]):
            if kinds_arr[i] == 0:
                vals_arr[i] = env[nm]
                in_ptrs[i] = 0; lens_arr[i] = 0; out_ptrs[i] = 0
            elif kinds_arr[i] == 1:
                buf = ctypes.create_string_buffer(bytes(ro_bytes[nm]), max(1, len(ro_bytes[nm])))
                in_keep.append(buf)
                in_ptrs[i] = ctypes.cast(buf, ctypes.c_void_p)
                lens_arr[i] = len(ro_bytes[nm])
                out_ptrs[i] = 0
            else:
                cap = buf_sizes[nm]
                buf = ctypes.create_string_buffer(max(1, cap))
                out_keep[nm] = (buf, cap)
                in_ptrs[i] = 0; lens_arr[i] = cap
                out_ptrs[i] = ctypes.cast(buf, ctypes.c_void_p)
        rc = library().run_forked(entry_off, n_args, kinds_arr, vals_arr, in_ptrs, lens_arr, out_ptrs,
                            ctypes.byref(rax_out), ctypes.byref(sig_out), 2)
        if rc != 0:
            why = {1: "clobbered a callee-saved register", 2: "left rsp moved", 3: "wrote bytes BEFORE output buffer",
                   4: f"crashed/timed out (signal/status {sig_out.value})", 5: "buffer too big"}[rc]
            return False, idx + 1, time.time() - t0, f"FALSE ({sym}, case {idx}): {why}\n  input: {format_case(c, env, buf_sizes, ro_bytes)}"
        out_bufs = {nm: buf.raw[:cap] for nm, (buf, cap) in out_keep.items()}
        bad = check_one(spec, c, env, buf_sizes, ro_bytes, rax_out.value, out_bufs)
        if bad is not None:
            return False, idx + 1, time.time() - t0, f"FALSE ({sym}, case {idx}): {bad}\n  input: {format_case(c, env, buf_sizes, ro_bytes)}"
    return True, len(samples), time.time() - t0, f"not refuted ({sym}): {len(samples)} inputs checked in {time.time() - t0:.2f} s"


def after_refusal(path, symbol, spec_path=None, cases=300):
    """One line for a driver to print after "NOT shown": FALSE with the input, or that these inputs refute
    nothing; None where the refuter cannot run here or has nothing to say."""
    if not available(): return None
    try:
        s, spec, public, at = load_spec_and_offsets(path, spec_path)
        if symbol not in spec.contracts or symbol not in at or library().init_runner(s.image, len(s.image)) != 0: return None
        ok, n, secs, msg = refute_symbol(s, spec, symbol, at[symbol], cases, 1)
    except (Exception, SystemExit) as err:
        return f"(no refutation tried: {str(err)[:100]})"
    return msg if not ok else f"(not refuted: {n} inputs run on this processor do as the contract says; so it is not shown, and nothing here says it is false)"


def main():
    args = [a for k, a in enumerate(sys.argv[1:], 1) if not a.startswith("--") and sys.argv[k - 1] not in ("--symbol", "--cases", "--seed")]
    opt = lambda n, d=None: sys.argv[sys.argv.index(n) + 1] if n in sys.argv else d
    bin_path = args[0]
    spec_path = args[1] if len(args) > 1 else None
    cases = int(opt("--cases", "200"))
    seed = int(opt("--seed", "1"))
    only_sym = opt("--symbol")

    s, spec, public, at = load_spec_and_offsets(bin_path, spec_path)
    if library().init_runner(s.image, len(s.image)) != 0:
        raise SystemExit("init_runner failed")
    syms = [only_sym] if only_sym else [nm for nm in public if nm in at]
    if not syms:
        raise SystemExit("no matching contract symbol found in binary")
    any_false = False
    for sym in syms:
        ok, n, secs, msg = refute_symbol(s, spec, sym, at[sym], cases, seed)
        print(msg)
        if not ok: any_false = True
    return 1 if any_false else 0


if __name__ == "__main__":
    sys.exit(main())
