"""C ABI interpreter cases v2: valid non-null context control and two API forms."""
import json,os,pathlib,subprocess,sys
repo=pathlib.Path(sys.argv[1]);r=pathlib.Path(sys.argv[2]);kinds=len(sys.argv)>3 and sys.argv[3]=='two-kinds'
project=r/'fixture';(project/'src').mkdir(parents=True,exist_ok=True)
source=(r/'capi-miri-main.rs').read_text()
if kinds:
    old='use b3::{hash, Hasher};'
    assert source.count(old)==1
    source=source.replace(old,'use b3::{convenience::hash, performance::Hasher};')
(project/'src/main.rs').write_text(source)
(project/'Cargo.toml').write_text('[package]\nname="capi-boundary-miri-v2"\nversion="0.0.0"\nedition="2024"\n[dependencies]\ncapi={package="blake3-servil-c",path='+json.dumps(str(repo/'capi'))+'}\nb3={package="blake3-servil",path='+json.dumps(str(repo))+',features=["pure"]}\n')
commit=subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip()
env=dict(os.environ,MIRIFLAGS=os.environ.get('MIRIFLAGS','-Zmiri-num-cpus=1'),CARGO_TARGET_DIR='/root/target-capi-miri-'+commit[:12])
cases=['batch-initialized','batch-uninitialized','xof-initialized','xof-uninitialized','stream-initialized','stream-uninitialized','stream-tail-uninitialized','stream-context-control','batch-overlap-control','stream-reentry-control','uninitialized-read-control']
results=[]
for case in cases:
    command=['cargo','+nightly-2026-10-24','miri','run','--manifest-path',str(project/'Cargo.toml'),'--',case]
    with (r/(case+'.log')).open('w') as log:
        try:code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,env=env,timeout=45).returncode
        except subprocess.TimeoutExpired:code='timeout'
    text=(r/(case+'.log')).read_text(errors='replace')
    result={'case':case,'exit':code,'miri_undefined_behavior_diagnostic':'error: Undefined Behavior:' in text,'completed_case':('case completed: '+case) in text}
    results.append(result);print(json.dumps(result),flush=True)
    (r/'outcomes.json').write_text(json.dumps({'fixture':'v2','source':commit,'two_kinds_api':kinds,'toolchain':'nightly-2026-10-24','MIRIFLAGS':env['MIRIFLAGS'],'native_execution':False,'cases':results},indent=2)+'\n')
    if case in ['batch-initialized','stream-context-control'] and code!=0:
        raise SystemExit('BLOCKED: required positive control did not complete')
print('C ABI interpreter cases complete; inspect diagnostic sites before conclusions',flush=True)
