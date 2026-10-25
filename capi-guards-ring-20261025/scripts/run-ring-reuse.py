"""Functional isolation probe only: dummy data, safe Rust, no timings."""
import json,os,pathlib,subprocess
r=pathlib.Path('/root/results/release-ring-reuse-20261025')
results=[]
for label,repo,kinds in [('main','/root/BLAKE3-release-current',False),('api','/root/BLAKE3-release-api-review',True)]:
 p=r/label;(p/'src').mkdir(parents=True,exist_ok=True)
 s=(r/'ring-reuse.rs').read_text()
 if kinds:
  a='use b3::{Hash, Mode, hash_with, stream};';assert s.count(a)==1
  s=s.replace(a,'use b3::{Hash, Mode, convenience::hash_with, performance::stream};')
 assert 'unsafe' not in s
 (p/'src/main.rs').write_text(s)
 (p/'Cargo.toml').write_text('[package]\nname="ring-reuse-probe"\nversion="0.0.0"\nedition="2024"\n[dependencies]\nb3={package="blake3-servil",path='+json.dumps(repo)+'}\n')
 pin=subprocess.check_output(['git','-C',repo,'rev-parse','HEAD'],text=True).strip()
 for interpreter in [False,True]:
  mode='miri' if interpreter else 'native'
  cmd=['cargo']+(['+nightly-2026-10-24','miri','run'] if interpreter else ['run','--release'])+['--manifest-path',str(p/'Cargo.toml')]
  env=dict(os.environ,CARGO_TARGET_DIR='/root/target-ring-reuse-'+label+'-'+mode,MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance')
  with (r/(label+'-'+mode+'.log')).open('w') as f:
   try:code=subprocess.run(cmd,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=120).returncode
   except subprocess.TimeoutExpired:code='timeout'
  text=(r/(label+'-'+mode+'.log')).read_text(errors='replace')
  result={'source':pin,'api':label,'execution':mode,'exit':code,'prior_dummy_material_observed':'all 64 bytes of prior dummy key material observed' in text,'miri_ub':'Undefined Behavior' in text}
  results.append(result);print(json.dumps(result),flush=True)
  (r/'results.json').write_text(json.dumps(results,indent=2)+'\n')
  if code!=0:raise SystemExit('Probe not established; inspect the failure before drawing conclusions')
