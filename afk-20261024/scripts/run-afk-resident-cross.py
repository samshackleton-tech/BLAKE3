#!/usr/bin/env python3
"""Validate the smaller GPR kernel's opt-in on both x86 routes, after timing
jobs finish; this is the version to offer for native Intel validation."""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import time

R=Path('/root/results/afk-20261024-resident-cross')
PREVIOUS=Path('/root/results/afk-20261024-direct-confirm')
HEAD='8e6f0a1a3fa016a7cb0528ed7fbf593b57600883'


def main():
    deadline=time.monotonic()+6*3600
    while True:
        if (PREVIOUS/'state.json').exists():
            state=json.loads((PREVIOUS/'state.json').read_text())
            if state.get('complete') or state.get('error'): break
        if (PREVIOUS/'SKIPPED.txt').exists(): break
        if time.monotonic()>deadline: raise TimeoutError('prior queue unfinished')
        time.sleep(10)
    with open('/root/bench-native-afk.lock','a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        R.mkdir(parents=True,exist_ok=False)
        wt=Path('/root/BLAKE3-gpr-resident-cross-x86')
        subprocess.run(['git','-C','/root/BLAKE3','fetch','-q','/root/gpr-resident-cross.bundle',
                        'experiment/sam-gpr-resident-cross-x86'],check=True)
        subprocess.run(['git','-C','/root/BLAKE3','worktree','add','-q','--detach',str(wt),HEAD],check=True)
        for variant in ['default','gpr']:
            env=os.environ.copy();env.pop('BLAKE3_DIAGNOSTIC_GPR',None)
            if variant=='gpr': env['BLAKE3_DIAGNOSTIC_GPR']='1'
            with (R/f'{variant}.log').open('w') as out:
                result=subprocess.run(['cargo','nextest','run','--release','--lib','--tests','--no-fail-fast'],
                                      cwd=wt,env=env,stdout=out,stderr=subprocess.STDOUT,timeout=600)
            (R/f'{variant}.exit').write_text(str(result.returncode)+'\n')
            if result.returncode: raise RuntimeError(variant+' failed')
        (R/'complete').write_text(HEAD+'\nBoth x86 entry routes tested natively on EPYC; no Intel timing claim.\n')


if __name__=='__main__': main()
