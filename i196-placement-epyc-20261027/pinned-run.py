#!/usr/bin/env python3
"""pinned-run: run a job on a remote machine from inputs named by content,
and accept its results only when they say they came from those inputs.

Why (Sam, October 27): wrong-version runs kept happening because inputs were
named by mutable things (branches, reused worktrees, paths on PATH, a lock
that ignores a patch) and results were judged by exit status. This tool:

  1. names every repository by a full 40-hex commit (branch names refused),
     and every script by its SHA-256;
  2. builds each run in a fresh directory: each repository fetched by hash
     and checked to be that commit; no worktree, target or lock reused;
  3. runs the script stored read-only under its hash, the hash recorded;
  4. verifies the outputs: each `expect` rule's strings must appear in the
     named files, and no `forbid` string (default: warnings that mean "I did
     something other than asked", such as Cargo's unused patch) may appear in
     any log; the run is marked VERIFIED or FAILED;
  5. fetches a run's results only when VERIFIED (--failed to fetch anyway,
     into a directory named FAILED-...).

Manifest (JSON):
  {"name": "...", "host": "root@1.2.3.4",
   "repos": [{"url": "https://github.com/o/r", "commit": "<40 hex>", "path": "src"}, ...],
   "script": "path/to/job.sh",            # local file; run as: bash job.sh RUN_DIR
   "env": {"K": "V"},                      # optional
   "lock": "/root/bench-native-afk.lock",  # optional: flock held for the job
   "expect": [{"file": "out/x.txt", "contains": ["commit <hash>", ...]}, ...],
   "forbid": ["..."]}                      # optional; added to the defaults

Commands:
  pinned-run launch MANIFEST      start; prints the run id
  pinned-run status HOST RUN_ID   running / VERIFIED / FAILED (+ reasons)
  pinned-run wait HOST RUN_ID     wait until done, print status
  pinned-run fetch HOST RUN_ID DEST [--failed]
On the remote side the same file (stored under its own hash) runs `remote-*`.
"""
import glob, hashlib, json, os, re, shlex, subprocess, sys, time

SSH = ["ssh", "-F", "/dev/null", "-i", os.path.expanduser("~/.ssh/id_ed25519"), "-o", "BatchMode=yes",
       "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-o", "LogLevel=ERROR",
       "-o", "ConnectTimeout=15"]
RUNS = "/root/pinned-runs"
DEFAULT_FORBID = [
    "was not used in the crate graph",      # Cargo: a [patch] silently ignored
    "raw profile version mismatch",         # an llvm tool from another LLVM
]
HEX40 = re.compile(r"[0-9a-f]{40}")

def die(msg):
    sys.exit(f"pinned-run: {msg}")

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def ssh(host, command, stdin=None, check=True):
    r = subprocess.run(SSH + [host, command], input=stdin, capture_output=True)
    if check and r.returncode != 0:
        die(f"{host}: {command[:80]}... exit {r.returncode}\n{r.stderr.decode(errors='replace')[-2000:]}")
    return r

def put(host, path, data, mode="0444"):
    """Write bytes to a remote path, then make it read-only."""
    q = shlex.quote(path)
    ssh(host, f"mkdir -p $(dirname {q}) && cat > {q}.tmp && chmod {mode} {q}.tmp && mv -f {q}.tmp {q}", stdin=data)

def validate(m):
    for key in ("name", "host", "repos", "script"):
        if key not in m:
            die(f"manifest lacks {key!r}")
    if not re.fullmatch(r"[A-Za-z0-9._-]+", m["name"]):
        die("name: letters, digits, . _ - only")
    paths = set()
    for r in m["repos"]:
        if not HEX40.fullmatch(r.get("commit", "")):
            die(f"{r.get('url')}: commit must be a full 40-hex hash, not {r.get('commit')!r}")
        p = r.get("path", "")
        if not p or p.startswith("/") or ".." in p.split("/") or p in paths:
            die(f"{r.get('url')}: bad or repeated path {p!r}")
        paths.add(p)
    for e in m.get("expect", []):
        if not e.get("file") or not e.get("contains"):
            die("each expect rule needs a file and contains")

def launch(manifest_path):
    m = json.load(open(manifest_path))
    validate(m)
    script = open(m["script"], "rb").read()
    tool = open(os.path.realpath(__file__), "rb").read()
    m["script_sha256"] = sha256(script)
    m["tool_sha256"] = sha256(tool)
    m["forbid"] = DEFAULT_FORBID + m.get("forbid", [])
    m["launched"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    body = json.dumps(m, indent=1, sort_keys=True).encode()
    run_id = f"{m['name']}-{time.strftime('%Y%m%dT%H%M%S', time.gmtime())}-{sha256(body)[:8]}"
    host, run = m["host"], f"{RUNS}/{run_id}"
    if ssh(host, f"test -e {run}", check=False).returncode == 0:
        die(f"{run} exists")
    put(host, f"{RUNS}/tools/pinned-run-{m['tool_sha256']}.py", tool)
    put(host, f"{RUNS}/scripts/job-{m['script_sha256']}.sh", script)
    put(host, f"{run}/manifest.json", body)
    tool_path = f"{RUNS}/tools/pinned-run-{m['tool_sha256']}.py"
    unit = "pinned-" + sha256(run_id.encode())[:12]
    ssh(host, f"systemd-run --unit={unit} --collect python3 {tool_path} remote-execute {run} >/dev/null 2>&1")
    print(run_id)

def status(host, run_id):
    r = ssh(host, f"cd {RUNS}/{shlex.quote(run_id)} && (cat STATUS 2>/dev/null || echo running); cat REASONS 2>/dev/null", check=False)
    return r.stdout.decode().strip()

# ---------------------------------------------------------------- remote side
def sh(cmd, cwd=None, log=None):
    r = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str), capture_output=True, text=True)
    if log:
        log.write(f"$ {cmd}\n{r.stdout}{r.stderr}exit {r.returncode}\n")
        log.flush()
    return r

def remote_execute(run):
    m = json.load(open(f"{run}/manifest.json"))
    os.makedirs(f"{run}/out", exist_ok=True)
    reasons = []
    with open(f"{run}/prepare.log", "w") as log:
        # Every repository fetched by hash into a fresh directory, and checked.
        # Git's objects are named by their hashes, so one mirror per URL is a
        # safe shared cache; each run clones from it, with full history (check
        # builds older commits), and origin set back to the real URL.
        for r in sorted(m["repos"], key=lambda r: r["path"].count("/")):
            d = f"{run}/{r['path']}"
            cache = f"{RUNS}/cache/{sha256(r['url'].encode())[:16]}.git"
            steps = []
            if not os.path.exists(cache):
                steps.append(["git", "clone", "-q", "--mirror", r["url"], cache])
            else:
                steps.append(["git", "-C", cache, "fetch", "-q", "--prune", "origin"])
            steps += [["sh", "-c", f"git -C {cache} cat-file -e {r['commit']}^{{commit}} || git -C {cache} fetch -q {shlex.quote(r['url'])} {r['commit']}"],
                      ["git", "-C", cache, "update-ref", f"refs/pinned/{r['commit']}", r["commit"]],
                      ["git", "init", "-q", d],
                      ["git", "-C", d, "remote", "add", "origin", r["url"]],
                      ["git", "-C", d, "fetch", "-q", cache, "+refs/*:refs/cache/*"],
                      ["git", "-C", d, "checkout", "-q", "--detach", r["commit"]]]
            for cmd in steps:
                p = sh(cmd, log=log)
                if p.returncode != 0:
                    reasons.append(f"prepare: {' '.join(cmd)} failed")
                    break
            head = sh(["git", "-C", d, "rev-parse", "HEAD"], log=log).stdout.strip()
            if head != r["commit"]:
                reasons.append(f"prepare: {r['path']} is {head}, not {r['commit']}")
        # The script, read-only under its hash, checked again before it runs.
        script = f"{RUNS}/scripts/job-{m['script_sha256']}.sh"
        if sha256(open(script, "rb").read()) != m["script_sha256"]:
            reasons.append("prepare: the stored script's hash changed")
    if not reasons:
        env = dict(os.environ, HOME="/root", RUN_DIR=run, **m.get("env", {}))
        cmd = ["bash", script, run]
        if m.get("lock"):
            cmd = ["flock", "-w", "86400", m["lock"]] + cmd
        with open(f"{run}/job.log", "w") as out:
            p = subprocess.run(cmd, cwd=run, env=env, stdout=out, stderr=subprocess.STDOUT)
        if p.returncode != 0:
            reasons.append(f"job: exit {p.returncode}")
        reasons += verify(run, m)
    with open(f"{run}/REASONS", "w") as f:
        f.write("".join(f"{x}\n" for x in reasons))
    with open(f"{run}/STATUS", "w") as f:
        f.write("FAILED\n" if reasons else "VERIFIED\n")

def verify(run, m):
    reasons = []
    for e in m.get("expect", []):
        files = sorted(glob.glob(os.path.join(run, e["file"])))
        if not files:
            reasons.append(f"expect: no file {e['file']}")
        for f in files:
            text = open(f, errors="replace").read()
            for s in e["contains"]:
                if s not in text:
                    reasons.append(f"expect: {os.path.relpath(f, run)} lacks {s!r}")
    logs = [f"{run}/job.log", f"{run}/prepare.log"] + glob.glob(f"{run}/out/**/*.log", recursive=True) \
        + glob.glob(f"{run}/out/**/*.err", recursive=True)
    for f in sorted(set(logs)):
        if os.path.exists(f):
            text = open(f, errors="replace").read()
            for s in m["forbid"]:
                if s in text:
                    reasons.append(f"forbid: {os.path.relpath(f, run)} says {s!r}")
    return reasons

def main():
    a = sys.argv[1:]
    if not a:
        die(__doc__)
    if a[0] == "launch" and len(a) == 2:
        launch(a[1])
    elif a[0] == "status" and len(a) == 3:
        print(status(a[1], a[2]))
    elif a[0] == "wait" and len(a) == 3:
        while (s := status(a[1], a[2])).startswith("running"):
            time.sleep(30)
        print(s)
    elif a[0] == "fetch" and len(a) in (4, 5):
        host, run_id, dest = a[1:4]
        s = status(host, run_id)
        ok = s.startswith("VERIFIED")
        if not ok and "--failed" not in a:
            die(f"{run_id} is not verified:\n{s}")
        target = os.path.join(dest, run_id if ok else f"FAILED-{run_id}")
        os.makedirs(target, exist_ok=True)
        # The run's records and outputs, never the checked-out sources.
        for part in ("manifest.json", "STATUS", "REASONS", "prepare.log", "job.log", "out"):
            subprocess.run(["rsync", "-a", "-e", " ".join(SSH), f"{host}:{RUNS}/{run_id}/{part}", target + "/"],
                           check=False)
        print(target)
    elif a[0] == "remote-execute" and len(a) == 2:
        remote_execute(a[1])
    else:
        die(__doc__)

main()
