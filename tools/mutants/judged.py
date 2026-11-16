"""Every mutant is judged on at least one platform (BLAKE3 #400).

    python3 tools/mutants/judged.py [--crate DIR] [--rows]

Each platform has a list of the mutants that survive its tests (known-ARCH.txt), each row with its reason.
Three rows in four say "same code": the mutant changes nothing that platform compiles (another
architecture's code, mostly), so no test there could catch it. Such a row is no judgement. Nothing joined
the lists: a mutant that is the same code on every platform had three rows and no judge, and nobody saw.

This reads the lists of every platform and the mutants the source holds (cargo mutants --list, which reads
the source unbuilt, every target's code alike) and says of each mutant where it is judged:

    caught      the platform mutates its file and does not list it: its tests catch it there
    reasoned    listed there with a reason a person wrote (equivalent, test-only code, a scheduling choice);
                or in that platform's time-outs with one (a wait that never returns: the clock is what catches it)

and where it is not:

    same code   listed there as the same code (or as another platform's same code)
    unexplained listed there as UNCLASSIFIED or OPEN
    timed out   in that platform's time-outs with no reason yet: the tests did not finish, which says nothing
    not mutated its file is not in that platform's `files:` line

A mutant judged nowhere is printed with what each platform says of it, and the exit status is 1. It needs no
build and no run, so it can be asked on any machine of any commit; it is as good as the lists are, which
each platform's whole run keeps true. --rows: how many "same code" rows each list holds, and how many of
those name a mutant judged on another platform (the rows that say nothing a reader needs).
Exit status: 0 every mutant is judged somewhere; 1 some are not; 2 it could not read the lists or the source.
"""
import collections, glob, os, re, subprocess, sys

CONDITION = re.compile(r"^\[cpu (has|lacks) ([A-Za-z0-9_.]+(?: [A-Za-z0-9_.]+)*)\] (.*)$")
PLACE = re.compile(r"^(\S+?):\d+:\d+: (.*)$")


def kind_of(reason):
    """same, unexplained or reasoned: what a row's reason is as a judgement. A row written from another
    platform's ("as on ARCH: survives (FILE): REASON; on ...") is what those reasons are."""
    if reason.startswith(("UNCLASSIFIED", "OPEN")): return "unexplained"
    if reason.startswith("as on "):
        parts = [p.split("): ", 1)[1] if "): " in p else p for p in reason[3:].split("; on ")]
        kinds = {kind_of(p) for p in parts}
        return "reasoned" if "reasoned" in kinds else "same" if kinds == {"same"} else "unexplained"
    return "same" if reason.startswith("same code:") else "reasoned"


def read_list(path):
    """(the files a platform mutates, {(file, mutant): [(places, condition or None, reason)]})."""
    files, rows = [], collections.defaultdict(list)
    for line in open(path):
        line = line.rstrip("\n")
        if line.startswith("files:"): files = line.split()[1:]
        elif line.startswith("model files:") or not line.strip() or line.startswith("#"): continue
        else:
            file, mutant, count, reason = line.split("\t", 3)
            m = CONDITION.match(reason)
            rows[(file, mutant)].append((int(count), (m.group(1), m.group(2)) if m else None, m.group(3) if m else reason))
    return files, rows


def on_platform(name, places, files, known, timed):
    """What one platform says of a mutant (see the module's words)."""
    if name[0] not in files: return "not mutated"
    rows = known.get(name, [])
    if not rows:
        late = timed.get(name, [])
        if sum(n for n, _, _ in late) < places: return "caught"
        return "reasoned" if {kind_of(reason) for _, _, reason in late} == {"reasoned"} else "timed out"
    conditions = [c for _, c, _ in rows if c is not None]
    # rows for some CPUs only, that do not between them cover every CPU: on the others it is not listed, so caught
    covered = any(c is None for _, c, _ in rows) or any(("has", f) in conditions and ("lacks", f) in conditions for _, f in conditions)
    kinds = {kind_of(reason) for _, _, reason in rows}
    if "reasoned" in kinds: return "reasoned"
    if not covered or max(n for n, _, _ in rows) < places: return "caught"       # at a place, or on a CPU, the list does not name
    return "same code" if kinds == {"same"} else "unexplained"


def join(listed, lists):
    """listed: cargo mutants --list's lines. lists: {arch: (files, known rows, timed rows)}.
    -> ({name: places}, {name: {arch: what it says}}, the names judged nowhere, in order)."""
    places = collections.Counter()
    for line in listed:
        m = PLACE.match(line)
        if m: places[(m.group(1), m.group(2))] += 1
    says = {name: {arch: on_platform(name, n, *lists[arch]) for arch in sorted(lists)} for name, n in places.items()}
    nowhere = sorted(name for name, by in says.items() if not any(v in ("caught", "reasoned") for v in by.values()))
    return places, says, nowhere


def lists_of(folder):
    out = {}
    for path in sorted(glob.glob(os.path.join(folder, "known-*.txt"))):
        arch = os.path.basename(path)[len("known-"):-len(".txt")]
        files, known = read_list(path)
        timeouts = os.path.join(folder, f"timeouts-{arch}.txt")
        out[arch] = (files, known, read_list(timeouts)[1] if os.path.exists(timeouts) else {})
    return out


def report(crate, listed, lists, rows=False, out=print):
    places, says, nowhere = join(listed, lists)
    label = f"the crate in {crate}/" if crate else "the root's crate"
    out(f"judged: {label}: {len(places)} mutants at {sum(places.values())} places; {len(places) - len(nowhere)} judged on at least one of {', '.join(sorted(lists))}")
    unmutated = collections.Counter(name[0] for name in nowhere if set(says[name].values()) == {"not mutated"})
    for file, n in sorted(unmutated.items()):
        out(f"  NO PLATFORM MUTATES {file}: its {n} mutants are judged nowhere (it is in no list's `files:` line)")
    for name in nowhere:
        if set(says[name].values()) == {"not mutated"}: continue
        out(f"  JUDGED NOWHERE: {name[0]}\t{name[1]}\t" + "; ".join(f"{arch}: {what}" for arch, what in sorted(says[name].items())))
    if rows:
        for arch, (files, known, _) in sorted(lists.items()):
            same = [name for name, rs in known.items() if {kind_of(r) for _, _, r in rs} == {"same"}]
            elsewhere = sum(1 for name in same if name in says and any(v in ("caught", "reasoned") for a, v in says[name].items() if a != arch))
            out(f"  {arch}: {sum(len(r) for r in known.values())} rows; {len(same)} mutants listed as the same code, {elsewhere} of them judged on another platform")
    return len(nowhere)


def main():
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip()
    crates = [sys.argv[sys.argv.index("--crate") + 1]] if "--crate" in sys.argv else [""] + sorted(
        d for d in os.listdir(os.path.join(root, "tools", "mutants")) if glob.glob(os.path.join(root, "tools", "mutants", d, "known-*.txt")))
    bad = 0
    for crate in crates:
        crate = "" if crate == "." else crate
        folder = os.path.join(root, "tools", "mutants", *([crate] if crate else []))
        lists = lists_of(folder)
        if not lists: print(f"judged: no lists in {folder}"); return 2
        args = ["cargo", "mutants", "--list", "--profile", "mutants"] + ([] if crate else ["--features", "serde,zeroize"])
        r = subprocess.run(args, cwd=os.path.join(root, crate) if crate else root, capture_output=True, text=True)
        if r.returncode: print(f"judged: cargo mutants --list failed: {r.stderr[-300:]}"); return 2
        bad += report(crate, r.stdout.splitlines(), lists, "--rows" in sys.argv)
    print("judged: every mutant is judged on at least one platform" if not bad else f"judged: {bad} mutants are judged on no platform")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
