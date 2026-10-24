#!/usr/bin/env python3
"""Small diagnostic after the queued work: one vzeroupper before the SIMD
kernel returns. Tests whether vector-state cleanup helps its in-place consumer.
Sixteen layouts, word producer only; no default/production adoption.
"""
import fcntl
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import time

R=Path('/root/results/afk-20261024-simd-cleanup')
FIRST=Path('/root/results/afk-20261024-runtime-control')
PREVIOUS=Path('/root/results/afk-20261024-cross-x86')
LIB_HEAD='2c48fa4d4693be87d46fccc92eb2b38c74a1c242'
BENCH_HEAD='84248f33eb0a8d196e8e17a68acc711f4a5c641f'


def main():
    deadline=time.monotonic()+6*3600
    while not (PREVIOUS/'complete').exists():
        if any(p.read_text().strip()!='0' for p in PREVIOUS.glob('*.exit')):
            break
        if time.monotonic()>deadline: raise TimeoutError('previous validation unfinished')
        time.sleep(20)
    with open('/root/bench-native-afk.lock','a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        R.mkdir(parents=True,exist_ok=False)
        first=json.loads((FIRST/'state.json').read_text())
        if not first.get('controls_pass') or not first.get('complete'):
            (R/'SKIPPED.txt').write_text('Controls not passed.\n');return
        spec=importlib.util.spec_from_file_location('queue','/root/run-afk-direct-flow-v2.py')
        q=importlib.util.module_from_spec(spec);spec.loader.exec_module(q)
        q.R=R;q.WT=Path('/root/BLAKE3-simd-upper-cleanup');q.BENCH=q.WT/'bench-hashes'
        q.LIB_HEAD,q.BENCH_HEAD=LIB_HEAD,BENCH_HEAD
        q.PATCH=f'patch."https://github.com/johnservil/BLAKE3".blake3-servil.path="{q.WT}"'
        q.STATE={'start':q.now(),'complete':False,'library':LIB_HEAD,'bench':BENCH_HEAD,'stages':[]}
        q.save()
        subprocess.run(['git','-C','/root/BLAKE3','fetch','-q','/root/simd-cleanup.bundle',
                        'experiment/sam-simd-upper-cleanup'],check=True)
        subprocess.run(['git','-C','/root/BLAKE3','worktree','add','-q','--detach',str(q.WT),LIB_HEAD],check=True)
        subprocess.run(['git','clone','-q','-b','experiment/sam-direct-flow-calibration-v2',
                        '/root/bench-direct-runtime-plant.bundle',str(q.BENCH)],check=True)
        subprocess.run(['git','-C',str(q.BENCH),'remote','set-url','origin',
                        'https://github.com/samshackleton-tech/bench-hashes'],check=True)
        shutil.copy2(FIRST/'symbols.txt',R/'symbols.txt')
        (R/'lld').mkdir();(R/'lld/ld.lld').symlink_to((FIRST/'lld/ld.lld').resolve())
        try:
            q.run(['cargo','nextest','run','--release','--lib','--tests','--no-fail-fast'],
                  'tests/library',cwd=q.WT,timeout=900)
            q.run(['cargo','--config',q.PATCH,'update','-q','-p','blake3-servil'],'setup/update')
            q.run(['cargo','nextest','run','--config',q.PATCH,'--release','--features','diag-direct-flow'],
                  'tests/bench',timeout=900)
            new=q.build_group('simd-cleanup')
            old=[FIRST/'bin/simd-words'/f'bench-{i}' for i in range(16)]
            q.compare_groups('upper-cleanup',old,new,'serial')
            q.STATE.update(complete=True,end=q.now());q.save()
            q.mark('SIMD cleanup diagnostic complete')
        except BaseException as error:
            q.STATE.update(error=repr(error),failed_at=q.now());q.save();raise


if __name__=='__main__': main()
