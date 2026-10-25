"""Each malformed C call must reach its guard, not a Miri UB diagnostic."""
import json,os,pathlib,re,subprocess
repo=pathlib.Path('/root/BLAKE3-capi-contracts')
r=pathlib.Path('/root/results/release-capi-guards-20261025')
source=(repo/'capi/tests/guards.rs').read_text().split('const CASES:',1)[1].split('];',1)[0]
cases=re.findall(r'\("([^"\n]+)", "([^"\n]+)"\)',source)
assert len(cases)==16,cases
base=['cargo','+nightly-2026-10-24','miri','nextest','run','--manifest-path','capi/Cargo.toml','--config-file','.config/nextest.toml','--profile','miri']
env=dict(os.environ,MIRIFLAGS='-Zmiri-num-cpus=1 -Zmiri-ignore-leaks -Zmiri-strict-provenance -Zmiri-env-forward=B3_CAPI_GUARD_CASE',CARGO_TARGET_DIR='/root/target-capi-guards-miri')
results=[]
for case,message in cases:
    log=r/(case+'.miri.log')
    with log.open('w') as f:
        try:code=subprocess.run(base+['--run-ignored','only','-E','test(bad_calls_stop_at_the_guard)'],cwd=repo,env=dict(env,B3_CAPI_GUARD_CASE=case),stdout=f,stderr=subprocess.STDOUT,timeout=120).returncode
        except subprocess.TimeoutExpired:code='timeout'
    text=log.read_text(errors='replace')
    item={'case':case,'exit':code,'diagnostic_found':message in text,'panic_found':'panicked at' in text,'miri_ub':'Undefined Behavior' in text}
    results.append(item)
    (r/'guard-miri-results.json').write_text(json.dumps({'source':subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip(),'MIRIFLAGS':env['MIRIFLAGS'],'results':results},indent=2)+'\n')
    print(json.dumps(item),flush=True)
    if not(code==100 and item['diagnostic_found'] and item['panic_found'] and not item['miri_ub']):
        raise SystemExit('BLOCKED: guard did not produce the expected pre-borrow diagnostic')
print('All guards stopped the calls without a Miri UB diagnostic',flush=True)
