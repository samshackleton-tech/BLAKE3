#!/bin/bash
# BLAKE3 #198 bisect (bisect.py, embedded below so its hash is this script's).
set -u
. /root/.cargo/env
export PATH="$(rustc --print sysroot)/lib/rustlib/x86_64-unknown-linux-gnu/bin:$PATH"
export GIT_AUTHOR_NAME='Sam Shackleton' GIT_COMMITTER_NAME='Sam Shackleton' GIT_AUTHOR_EMAIL='samshackleton-tech@users.noreply.github.com' GIT_COMMITTER_EMAIL='samshackleton-tech@users.noreply.github.com'
R="$1"; mkdir -p "$R/out"
{ grep -m1 'model name' /proc/cpuinfo; nproc; sort -u /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; rustc -V; } > "$R/out/machine.txt"
cat > "$R/bisect198.py" <<'PY_EOF'
#!/usr/bin/env python3
"""BLAKE3 #198: bisect the release line's first-parent commits c75daeb..b5b988d8
for mt ManyMessages 16384 on this machine, each candidate X measured against
candidate/base-0.8 (bfbda192, old bench 5be5f236) as the release check measures:
check --cells all builds both sides' layouts, then regress runs the one cell,
PAIRS pairs, on those builds. X's bench is the one whose API X has.
Usage: bisect.py RUN_DIR   (RUN_DIR/src: the fork with history; writes RUN_DIR/out)"""
import json, os, re, statistics, subprocess, sys, time

R = sys.argv[1]; SRC = f"{R}/src"; O = f"{R}/out"; os.makedirs(O, exist_ok=True)
OLD, OLDBENCH = "bfbda1920283335ff3802723db11c209159f47fc", "5be5f23699ee7146ada56a08777173a4ee1c7bde"
GOOD0, BAD0 = "c75daeb", "b5b988d8982bea9490c38c79ec4b8c5c2428270c"
CELL, CONT, POINT, PAIRS = "blake3-servil-mt|solo|ManyMessages|16384", "blake3-servil-mt", "16384", 32
# The bench whose own pin is the newest ancestor of a chain position, by position on
# the first-parent chain c75daeb..b5b988d8 (pins enter at 9, 58, 82, 89). If it does
# not build, the neighbouring benches are tried.
SEGMENTS = [(0, OLDBENCH), (9, "774fb501f42734b36991dd2230a82d3385ad3127"),
            (58, "3f9edd139b2b1388c762ab82b4584cd09f3c53a7"), (82, "fbfa9876d76be42b077fd781705fb4cdb7dcde0c"),
            (89, "f17a161b6c19a2a639da0e19f82d44975a841bef")]
POS = {}
LOG = open(f"{O}/bisect.log", "a")
def log(*a):
    print(time.strftime("%H:%M:%S"), *a, file=LOG, flush=True)
def sh(cmd, **k):
    return subprocess.run(cmd, shell=isinstance(cmd, str), capture_output=True, text=True, **k)
def git(*a):
    return sh(["git", "-C", SRC, *a]).stdout.strip()

def benches_for(x):
    i = POS[x]
    k = max(j for j, (start, _) in enumerate(SEGMENTS) if start <= i)
    order = [k] + [j for j in sorted(range(len(SEGMENTS)), key=lambda j: abs(j - k)) if j != k]
    return [SEGMENTS[j][1] for j in order[:3]]

def measure(x, tag):
    x = git("rev-parse", x); d = f"{R}/w-{x[:10]}-{tag}"; o = f"{O}/{x[:10]}-{tag}"; os.makedirs(o, exist_ok=True)
    if not os.path.exists(d):
        sh(["git", "-C", SRC, "worktree", "add", "-q", "--detach", d, x])
    for b in benches_for(x):
        r = measure_with(x, tag, d, o, b)
        if r != "nobuild": return r
    log(x[:10], "no bench builds it"); return None

def measure_with(x, tag, d, o, b):
    bd = f"{d}/bench-hashes"
    if not os.path.exists(bd):
        sh(["git", "clone", "-q", "https://github.com/johnservil/bench-hashes", bd])
    for remote in ("https://github.com/johnservil/bench-hashes", "https://github.com/devonjonte/bench-hashes"):
        if sh(["git", "-C", bd, "cat-file", "-e", b + "^{commit}"]).returncode == 0: break
        sh(["git", "-C", bd, "fetch", "-q", remote, b]); sh(["git", "-C", bd, "fetch", "-q", remote])
    if sh(["git", "-C", bd, "checkout", "-q", "-f", "--detach", b]).returncode != 0:
        log(x[:10], "bench checkout failed", b); return "nobuild"
    for remote in ("https://github.com/johnservil/bench-hashes", "https://github.com/devonjonte/bench-hashes"):
        if sh(["git", "-C", bd, "cat-file", "-e", OLDBENCH + "^{commit}"]).returncode == 0: break
        sh(["git", "-C", bd, "fetch", "-q", remote, "candidate/bench-blocks-old-side"])
    if sh(["git", "-C", d, "cat-file", "-e", OLD]).returncode != 0:
        sh(["git", "-C", d, "fetch", "-q", "https://github.com/johnservil/BLAKE3", "candidate/base-0.8"])
    if sh("cargo build --release", cwd=bd).returncode != 0:
        log(x[:10], "bench build failed", b); return "nobuild"
    t = time.time()
    oldbench = [] if b == OLDBENCH else ["--old-bench", OLDBENCH]  # 5be5f236 predates --old-bench; one bench both sides
    c = sh(["flock", "-w", "7200", "/root/bench-native-afk.lock", "cargo", "run", "--release", "--", "check",
            "--against", OLD, *oldbench, "--cells", "all"], cwd=bd)
    open(f"{o}/check.out", "w").write(c.stdout); open(f"{o}/check.err", "w").write(c.stderr)
    C = f"{d}/target/check"
    ls = lambda s: [f"{C}/{s}/bench-hashes-{k}" for k in sorted(int(n.split("-")[-1]) for n in os.listdir(f"{C}/{s}") if re.fullmatch(r"bench-hashes-\d+", n))] if os.path.isdir(f"{C}/{s}") else []
    old, new = ls("old"), ls("new")
    if not old or not new:
        log(x[:10], "check built no layouts with bench", b[:10], c.returncode, c.stderr[-200:].replace("\n", " "))
        sh(["rm", "-rf", f"{d}/target"]); return "nobuild"
    rg = sh(["flock", "-w", "7200", "/root/bench-native-afk.lock", f"{bd}/target/release/bench-hashes", "regress",
             "--contenders", CONT, "--points", POINT, "--judge", CELL, "--pairs", str(PAIRS), "--keep", f"{o}/samples",
             *old, "--", *new], cwd=bd)
    open(f"{o}/regress.out", "w").write(rg.stdout + rg.stderr)
    ratios = pair_ratios(f"{o}/samples")
    med = statistics.median(ratios) if ratios else float("nan")
    slower = "regress: REGRESSION" in rg.stdout + rg.stderr
    sh(["git", "-C", bd, "checkout", "-q", "--", "index.html"])
    res = {"commit": x, "bench": b, "median": med, "slower": slower, "new_slower_pairs": sum(r > 1 for r in ratios),
           "pairs": len(ratios), "layouts": [len(old), len(new)], "check_exit": c.returncode, "minutes": round((time.time() - t) / 60, 1)}
    log(x[:10], json.dumps(res)); json.dump(res, open(f"{o}/result.json", "w"))
    sh(["rm", "-rf", f"{d}/target"])
    return res

def pair_ratios(d):
    runs = []
    for f in sorted(os.listdir(d)):
        if not re.fullmatch(r"run-\d+-(old|new)\.tsv", f): continue
        hdr = None; v = None
        for line in open(f"{d}/{f}"):
            if line.startswith("#"): continue
            p = line.rstrip("\n").split("\t")
            if hdr is None: hdr = p; continue
            r = dict(zip(hdr, p))
            if "|".join((r["contender"], r["scenario"], r["use_case"], r["point"])) == CELL:
                ns = u = 0.0
                for s in r["ns/units"].split(","):
                    a, b = s.split("/"); ns += float(a); u += float(b)
                v = ns / u
        runs.append((f.endswith("new.tsv"), v))
    out = []
    for i in range(0, len(runs) - 1, 2):
        (an, av), (bn, bv) = runs[i], runs[i + 1]
        if av and bv and an != bn:
            out.append((av / bv) if an else (bv / av))
    return out

def verdict(x):
    """bad (slower), good (level), or None (could not measure)."""
    for attempt in range(2):
        r = measure(x, f"m{attempt}")
        if r is None: return None
        if r["slower"] and r["median"] > 1.03: return "bad"
        if not r["slower"] and r["median"] < 1.02: return "good"
        log(x[:10], "ambiguous, measuring again")
    return "bad" if r["median"] >= 1.03 else "good"

chain = git("rev-list", "--first-parent", "--reverse", f"{GOOD0}..{BAD0}").split()
chain = [git("rev-parse", GOOD0)] + chain
POS.update({c: i for i, c in enumerate(chain)})
log("chain", len(chain), "commits", chain[0][:10], "..", chain[-1][:10])
lo, hi = 0, len(chain) - 1
# The tag's endpoint was measured by run i198-bisect-icelake-20261031T113230-ed72a6ff:
# x1.073, 31 of 32 pairs slower, judged slower. KNOWN_BAD=1 takes that result.
# c75daeb's endpoint: run i198-bisect-icelake-20261031T120129-cd47e7a0, x0.993, 13 of 32 slower, level.
ends = () if os.environ.get("KNOWN_ENDS") == "1" else ((hi, "bad"), (lo, "good"))
for end, want in ends:
    v = verdict(chain[end]); log("endpoint", chain[end][:10], v)
    if v != want:
        log("endpoint is not", want, "- stopping"); json.dump({"stopped": f"{chain[end]} is {v}, not {want}"}, open(f"{O}/bisect.json", "w")); sys.exit(0)
skipped = set()
while hi - lo > 1:
    mid = (lo + hi) // 2
    while mid in skipped and mid < hi - 1: mid += 1
    v = verdict(chain[mid]); log("step", mid, chain[mid][:10], v)
    if v is None: skipped.add(mid); 
    elif v == "bad": hi = mid
    else: lo = mid
    if all(i in skipped for i in range(lo + 1, hi)) and hi - lo > 1: break
first_bad = chain[hi]
msg = git("log", "-1", "--format=%H %s", first_bad)
json.dump({"last_good": chain[lo], "first_bad": first_bad, "subject": msg, "skipped": [chain[i] for i in sorted(skipped)]}, open(f"{O}/bisect.json", "w"), indent=1)
log("FIRST BAD", msg)
PY_EOF
python3 "$R/bisect198.py" "$R"
