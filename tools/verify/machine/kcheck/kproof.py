"""kproof: the form a proof travels in (the section `.ode.proof` of a file, or a file beside it), read.

    ode proof 1
    specification sha256 HEX            which specification the maker had (a reader compares it with his own)
    code LENGTH sha256 HEX begins HEX   the code the proof is of (to find it by its bytes in a file without names)
    at OFFSET NAME                      where each function is in that code
    file NAME LENGTH                    and then LENGTH bytes: the specification; the places of loops; the
                                        contracts of the functions inside; lemmas; the arithmetic's proofs

Nothing of it is trusted: each part is something a verifier checks or only uses to find its way."""
import kcheck


def carried(text):
    """A proof as klink.py writes it: {"spec": sha256, "code": (length, sha256, its first bytes), "at": {name: offset}, "files": {name: bytes}}."""
    out, at = {"at": {}, "files": {}}, 0
    def line():
        nonlocal at
        end = text.index(b"\n", at); l = text[at:end].decode(); at = end + 1
        return l.split(" ")
    if line() != ["ode", "proof", "1"]: raise kcheck.Fail("the proof is not one this verifier reads")
    while at < len(text):
        w = line()
        if w[0] == "specification" and w[1] == "sha256": out["spec"] = w[2]
        elif w[0] == "code" and w[2] == "sha256" and w[4] == "begins": out["code"] = (int(w[1]), w[3], bytes.fromhex(w[5]))
        elif w[0] == "at": out["at"][w[2]] = int(w[1])
        elif w[0] == "file": out["files"][w[1]] = text[at:at + int(w[2])]; at += int(w[2])
        else: raise kcheck.Fail(f"the proof: a line this verifier does not know: {' '.join(w)[:60]}")
    return out
