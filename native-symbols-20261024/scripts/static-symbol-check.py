"""Assembly-only check: renaming the inherited symbols changes no .text bytes."""
import hashlib,json,pathlib,subprocess
root=pathlib.Path(__file__).resolve().parent
repo=pathlib.Path('/home/samshackleton/work/BLAKE3-private-symbols-review')
out=root/'static-symbol-check'
out.mkdir(exist_ok=True)
results=[]
for isa in ['sse41','avx2','avx512']:
    source=repo/'c'/f'blake3_{isa}_x86-64_unix.S'
    private=out/f'{isa}-private.S'
    private.write_text(source.read_text().replace('blake3_','blake3_servil_'))
    for kind,path in [('original',source),('private',private)]:
        obj=out/f'{isa}-{kind}.o'
        text=out/f'{isa}-{kind}.text'
        subprocess.run(['cc','-c','-mavx512f','-mavx512vl',str(path),'-o',str(obj)],check=True)
        subprocess.run(['objcopy','--only-section=.text','-O','binary',str(obj),str(text)],check=True)
    a=out/f'{isa}-original.text';b=out/f'{isa}-private.text'
    assert a.read_bytes()==b.read_bytes(),isa
    results.append({'isa':isa,'text_bytes':a.stat().st_size,'identical':True,'sha256':hashlib.sha256(a.read_bytes()).hexdigest(),'blake3':subprocess.check_output(['b3sum',str(a)],text=True).split()[0]})
(out/'result.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
