"""Interpret C ABI boundary cases. Invalid controls are never run natively."""
import json,os,pathlib,subprocess
r=pathlib.Path('/root/results/release-capi-miri-20261025')
project=r/'fixture'
(project/'src').mkdir(parents=True,exist_ok=True)
(project/'src/main.rs').write_bytes((r/'capi-miri-main.rs').read_bytes())
(project/'Cargo.toml').write_text('''[package]
name="capi-boundary-miri"
version="0.0.0"
edition="2024"
[dependencies]
capi={package="blake3-servil-c",path="/root/BLAKE3-release-current/capi"}
b3={package="blake3-servil",path="/root/BLAKE3-release-current",features=["pure"]}
''')
env=dict(os.environ,MIRIFLAGS='-Zmiri-num-cpus=1',CARGO_TARGET_DIR='/root/target-capi-boundary-miri')
cases=['batch-initialized','batch-uninitialized','xof-initialized','xof-uninitialized','stream-initialized','stream-uninitialized','batch-overlap-control','stream-reentry-control','uninitialized-read-control']
results=[]
for case in cases:
    command=['cargo','+nightly-2026-10-24','miri','run','--manifest-path',str(project/'Cargo.toml'),'--',case]
    with (r/(case+'.log')).open('w') as log:
        try:
            code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,env=env,timeout=45).returncode
        except subprocess.TimeoutExpired:
            code='timeout'
    text=(r/(case+'.log')).read_text(errors='replace')
    result={'case':case,'exit':code,'miri_undefined_behavior_diagnostic':'error: Undefined Behavior:' in text,'completed_case':('case completed: '+case) in text}
    results.append(result)
    print(json.dumps(result),flush=True)
    (r/'outcomes.json').write_text(json.dumps({'source':'c75daebf383820e73bbe366d9e770d6168b236e6','toolchain':'nightly-2026-10-24','MIRIFLAGS':env['MIRIFLAGS'],'native_execution':False,'cases':results},indent=2)+'\n')
    if case=='batch-initialized' and code!=0:
        raise SystemExit('Stop: the initialized baseline did not complete; remaining cases are blocked')
subprocess.run(['git','-C','/root/BLAKE3-release-current','rev-parse','HEAD'],stdout=(r/'source-commit.txt').open('w'),check=True)
print('C ABI interpreter cases complete; evaluate controls before conclusions',flush=True)
