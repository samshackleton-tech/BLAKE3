#!/usr/bin/env python3
"""Does the proof of `hex` on x86-64 notice a changed instruction or a false statement? Each change is made
in a copy of this folder and of ../spec, and `lake build Meets_hex_bytes` must then fail. The control: the
unchanged copy, built afresh, must be accepted. Written by the experiment's make-hex-tree.py from its lists.
usage: mutants.py [JOBS]"""
import concurrent.futures, pathlib, shutil, subprocess, sys, tempfile

here = pathlib.Path(__file__).resolve().parent
jobs = int(sys.argv[1]) if len(sys.argv) > 1 else 4
MUTANTS = [('5002E', '.psrlw 2 4', '.psrlw 2 3', 'the high bits shifted by three'),
 ('50033', '.pand 2 (.x 5)', '.pand 2 (.x 6)', 'the high bits masked with nines'),
 ('50037', '.pand 0 (.x 5)', '.pand 0 (.x 7)', 'the low bits masked with 39s'),
 ('5003F', '.punpcklbw 3 (.x 0)', '.punpckhbw 3 (.x 0)', 'the high eight bytes twice'),
 ('50009', '0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F#128', '0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F07#128', "one byte's mask is 7"),
 ('50011', '0x09090909090909090909090909090909#128', '0x0909090909090909090909090909090A#128', "one byte's ten is a digit"),
 ('50019', '0x27272727272727272727272727272727#128', '0x27272727272727272727272727272707#128', "one byte's letters are capitals"),
 ('50021', '0x30303030303030303030303030303030#128', '0x30303030303030303030303030303031#128', "one byte's zero is '1'"),
 ('50000', '.movv false 0 (.m .rsi 0x0)', '.movv false 0 (.m .rsi 0x1)', 'the hash read from its second byte'),
 ('50004', '.movv false 1 (.m .rsi 0x10)', '.movv false 1 (.m .rsi 0x0)', 'the first half twice')]
STATEMENTS = [('../spec/HexText.lean', '[char (b >>> 4), char (b &&& 15#8)]', '[char (b &&& 15#8), char (b >>> 4)]', "a byte's low four bits come first"),
 ('../spec/HexText.lean', 'then n + 0x30#8 else n + 0x57#8', 'then n + 0x30#8 else n + 0x37#8', 'the letters are capitals'),
 ('../spec/HexText.lean', 'if n < 10#8 then', 'if n < 11#8 then', 'ten is written as a digit'),
 ('Spec_hex.lean', '(Bytes.layout 64).fills out (Hex.text hash)', '(Bytes.layout 64).fills out (Hex.text hash.reverse)', 'the hash is written backwards'),
 ('Spec_hex.lean', '(Bytes.layout 64).fills out (Hex.text hash)', '(Bytes.layout 63).fills out (Hex.text hash)', 'only 63 bytes may change'),
 ('Spec_hex.lean', 'reads := [(Bytes.layout 32).keeps inp hash]', 'reads := [(Bytes.layout 31).keeps inp hash]', 'the hash is 31 bytes'),
 ('Spec_hex.lean', 'args := [out, inp]', 'args := [inp, out]', 'the arguments the other way round'),
 ('Spec_hex.lean', 'returns := fun _ => True', 'returns := fun r => r = 0#64', 'it returns zero'),
 ('Meets_hex.lean', 'Abi.MeetsQuietly Code_hex.prog 0x50000', 'Abi.MeetsQuietly Code_hex.prog 0x50004', 'it is entered at its second instruction'),
 ('Meets_hex.lean',
  '(fun hash : List (BitVec 8) => Hex.contract out inp hash)',
  '(fun hash : List (BitVec 8) => Hex.contract out (inp + (hash.headD 0#8).zeroExtend 64) hash)',
  "the hash's place depends on the hash"),
 ('Spec_bytes.lean', 'm (a + BitVec.ofNat 64 i) = some bs[i]', 'm (a + BitVec.ofNat 64 (i + 1)) = some bs[i]', 'bytes are in memory one place later'),
 ('../spec/HexContract.lean', '(Bytes.plain 64).fills out (Hex.text hash)', '(Bytes.plain 64).fills out (Hex.text hash.reverse)', 'the contract: the hash is written backwards'),
 ('../spec/HexContract.lean', '(Bytes.plain 64).fills out (Hex.text hash)', '(Bytes.plain 63).fills out (Hex.text hash)', 'the contract: only 63 bytes may change'),
 ('../spec/HexContract.lean', 'reads := [(Bytes.plain 32).keeps inp hash]', 'reads := [(Bytes.plain 31).keeps inp hash]', 'the contract: the hash is 31 bytes'),
 ('../spec/HexContract.lean', 'args := [out, inp]', 'args := [inp, out]', 'the contract: the arguments the other way round'),
 ('../spec/HexContract.lean', 'returns := fun _ => True', 'returns := fun r => r = 0#64', 'the contract: it returns zero'),
 ('../spec/Contract.lean',
  'def plain (n : Nat) : Layout (List (BitVec 8)) := ⟨n, fun b v => b = v⟩',
  'def plain (n : Nat) : Layout (List (BitVec 8)) := ⟨n, fun b v => b = v.reverse⟩',
  'plain bytes are said to be in memory backwards')]


def check(job):
    with tempfile.TemporaryDirectory(prefix="mut-hex-") as d:
        d = pathlib.Path(d)
        work = d / "x86"
        skip = shutil.ignore_patterns(".lake", "lake-manifest.json", "*.log", "*.o")
        shutil.copytree(here, work, ignore=skip)
        shutil.copytree(here.parent / "spec", d / "spec", ignore=skip)
        if job is not None and len(job[0]) == 5:        # an instruction, by its address: the table's row and its lemma
            at, old, new, what = job
            text = (work / "Code_hex.lean").read_text()
            lines = [l for l in text.split("\n") if f"0x{at}," in l or f"at_{at} " in l]
            if len(lines) != 2 or any(old not in l for l in lines):
                return "MALFORMED", what
            for l in lines:
                text = text.replace(l, l.replace(old, new))
            (work / "Code_hex.lean").write_text(text)
        elif job is not None:                             # a line of what is claimed
            file, old, new, what = job
            text = (work / file).read_text()
            if file.endswith("HexText.lean"):             # without the specification's own example: the machine proof must object
                text = text[:text.index("/-- For example")]
            if text.count(old) != 1:
                return "MALFORMED", what
            (work / file).write_text(text.replace(old, new))
        else:
            what = "the unchanged copy"
        try:
            r = subprocess.run(["lake", "build", "Meets_hex_bytes"], cwd=work, capture_output=True, text=True, timeout=1500)
        except subprocess.TimeoutExpired:
            return "rejected", what + " (time limit)"
        out = r.stdout + r.stderr
        ok = r.returncode == 0 and "sorryAx" not in out and "'hex_meets_bytes' depends on axioms" in out
        return ("ACCEPTED" if ok else "rejected"), what


verdict, _ = check(None)
print(f"control: the unchanged copy is {verdict}", flush=True)
if verdict != "ACCEPTED":
    sys.exit("the control failed: the audit proves nothing")
bad = False
for name, group in (("changed instructions", MUTANTS), ("false statements", STATEMENTS)):
    tally = {}
    with concurrent.futures.ThreadPoolExecutor(jobs) as pool:
        for verdict, what in pool.map(check, group):
            tally[verdict] = tally.get(verdict, 0) + 1
            print(f"{verdict}\t{what}", flush=True)
    print(f"{len(group)} {name}: " + ", ".join(f"{n} {k}" for k, n in sorted(tally.items())), flush=True)
    bad = bad or set(tally) != {"rejected"}
sys.exit(1 if bad else 0)
