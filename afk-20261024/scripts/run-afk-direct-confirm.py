#!/usr/bin/env python3
"""Directly compare the resident-D candidate with SIMD, using retained
16-layout sets on both producers. Also compare with SIMD upper-state cleanup
when available. No percentages inferred by composing prior comparisons.
"""
import fcntl
import importlib.util
import json
from pathlib import Path
import time

R=Path('/root/results/afk-20261024-direct-confirm')
BASE=Path('/root/results/afk-20261024-runtime-control')
RESIDENT=Path('/root/results/afk-20261024-resident-d')
CLEANUP=Path('/root/results/afk-20261024-simd-cleanup')


def main():
    deadline=time.monotonic()+6*3600
    state={}
    while True:
        if (CLEANUP/'state.json').exists():
            state=json.loads((CLEANUP/'state.json').read_text())
            if state.get('complete') or state.get('error'): break
        if (CLEANUP/'SKIPPED.txt').exists(): break
        if time.monotonic()>deadline: raise TimeoutError('previous diagnostic unfinished')
        time.sleep(20)
    with open('/root/bench-native-afk.lock','a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        R.mkdir(parents=True,exist_ok=False)
        rstate=json.loads((RESIDENT/'state.json').read_text())
        if not rstate.get('complete'):
            (R/'SKIPPED.txt').write_text('Resident-D validation did not complete.\n');return
        spec=importlib.util.spec_from_file_location('queue','/root/run-afk-direct-flow-v2.py')
        q=importlib.util.module_from_spec(spec);spec.loader.exec_module(q)
        q.R=R;q.STATE={'start':q.now(),'complete':False,'stages':[]}
        q.save()
        try:
            for producer,old_name,new_name in [('words','simd-words','resident-words'),('fill','simd-fill','resident-fill')]:
                old=[BASE/'bin'/old_name/f'bench-{i}' for i in range(16)]
                new=[RESIDENT/'bin'/new_name/f'bench-{i}' for i in range(16)]
                assert all(p.exists() for p in old+new)
                q.compare_groups('simd-vs-resident-'+producer,old,new,'serial')
            if state.get('complete'):
                old=[CLEANUP/'bin/simd-cleanup'/f'bench-{i}' for i in range(16)]
                new=[RESIDENT/'bin/resident-words'/f'bench-{i}' for i in range(16)]
                assert all(p.exists() for p in old+new)
                q.compare_groups('cleanup-vs-resident',old,new,'serial')
            q.STATE.update(complete=True,end=q.now());q.save();q.mark('Direct confirmations complete')
        except BaseException as error:
            q.STATE.update(error=repr(error),failed_at=q.now());q.save();raise


if __name__=='__main__': main()
