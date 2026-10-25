"""Small diagnostic subset using the repository's proof engine, not a full campaign."""
import pathlib,sys
root=pathlib.Path('/root/BLAKE3-round-pr166')
sys.path.insert(0,str(root/'tools/verify'))
import prove_x86
cases=[]
for isa in ['avx2','avx512']:
    cases.append((isa,False,'hash_many',(2,15,True)))
for n in [1,32,33]:
    cases.append(('avx512',False,'xof_many',n))
for case in cases:
    # XOF33 is deliberately outside the single-call proved range; the
    # production wrapper splits it, so this case must not be overclaimed.
    if case[2]=='xof_many' and case[3]==33:
        continue
    got, verdict=prove_x86.prove_case(case)
    print(got,verdict,flush=True)
    assert not verdict.startswith('NOT PROVED'),(got,verdict)
print('selected new-shape proofs complete',flush=True)
