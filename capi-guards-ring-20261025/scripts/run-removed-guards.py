"""Miri-only mutation controls; never run these malformed calls natively."""
import json,os,pathlib,subprocess
repo=pathlib.Path('/root/BLAKE3-capi-guards-control')
r=pathlib.Path('/root/results/release-capi-guards-20261025/removed-controls');r.mkdir(exist_ok=True)
env=dict(os.environ,MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance -Zmiri-env-forward=B3_CAPI_GUARD_CASE',CARGO_TARGET_DIR='/root/target-capi-removed-guards-miri')
base=['cargo','+nightly-2026-10-24','miri','nextest','run','--release','--manifest-path','capi/Cargo.toml','--config-file','.config/nextest.toml','--profile','miri','--run-ignored','only','-E','test(bad_calls_stop_at_the_guard)']
rows=[]
for case,expected in [('callback-null','the done callback is NULL'),('hasher-init-alignment','the hasher is not 64-byte aligned'),('batch-overlap','input and output ranges overlap')]:
 with (r/(case+'.log')).open('w') as f:
  try:code=subprocess.run(base,cwd=repo,env=dict(env,B3_CAPI_GUARD_CASE=case),stdout=f,stderr=subprocess.STDOUT,timeout=120).returncode
  except subprocess.TimeoutExpired:code='timeout'
 text=(r/(case+'.log')).read_text(errors='replace')
 row={'case':case,'exit':code,'guard_diagnostic':expected in text,'miri_ub':'Undefined Behavior' in text,'unsafe_precondition':'unsafe precondition' in text}
 rows.append(row);print(json.dumps(row),flush=True)
 (r/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
 assert code==100 and not row['guard_diagnostic'] and (row['miri_ub'] or row['unsafe_precondition']),row
subprocess.run(['git','rev-parse','HEAD'],cwd=repo,stdout=(r/'source-commit.txt').open('w'),check=True)
