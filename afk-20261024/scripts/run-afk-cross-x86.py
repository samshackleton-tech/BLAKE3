#!/usr/bin/env python3
"""Last short validation: make the diagnostic GPR entry testable on Intel
without AVX-512. No speed verdict; do not change the binaries earlier jobs use.
"""
import fcntl
import json
from pathlib import Path
import subprocess
import time

R=Path('/root/results/afk-20261024-cross-x86')
PREVIOUS=Path('/root/results/afk-20261024-resident-d')
HEAD='7092ac5f99810718ab5e5c02c0cfef19dc81fd6e'


def main():
    deadline=time.monotonic()+6*3600
    while True:
        if (PREVIOUS/'SKIPPED.txt').exists():
            break
        if (PREVIOUS/'state.json').exists():
            state=json.loads((PREVIOUS/'state.json').read_text())
            if state.get('complete') or state.get('error'):
                break
        if time.monotonic()>deadline:
            raise TimeoutError('previous queue unfinished')
        time.sleep(20)
    with open('/root/bench-native-afk.lock','a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        R.mkdir(parents=True,exist_ok=False)
        wt=Path('/root/BLAKE3-gpr-cross-x86')
        subprocess.run(['git','-C','/root/BLAKE3','fetch','-q','/root/gpr-cross-x86.bundle',
                        'experiment/sam-gpr-cross-x86'],check=True)
        subprocess.run(['git','-C','/root/BLAKE3','worktree','add','-q','--detach',str(wt),HEAD],check=True)
        import os
        for variant in ['default','gpr']:
            env=os.environ.copy();env.pop('BLAKE3_DIAGNOSTIC_GPR',None)
            if variant=='gpr': env['BLAKE3_DIAGNOSTIC_GPR']='1'
            with (R/f'{variant}.log').open('w') as out:
                p=subprocess.run(['cargo','nextest','run','--release','--lib','--tests','--no-fail-fast'],
                                 cwd=wt,env=env,stdout=out,stderr=subprocess.STDOUT,timeout=600)
            (R/f'{variant}.exit').write_text(str(p.returncode)+'\n')
            if p.returncode: raise RuntimeError(f'{variant} tests failed')
        (R/'complete').write_text('Native EPYC tests passed on both routes; Intel timings still pending.\n')


if __name__=='__main__':
    main()
