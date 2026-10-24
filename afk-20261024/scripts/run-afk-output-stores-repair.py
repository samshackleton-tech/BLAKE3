#!/usr/bin/env python3
"""Last AFK job: unchanged GPR arithmetic, digest emitted with two 16-byte
stores. Waits for both earlier queues. Measure both direct producers using
bench-hashes; first run ABI/differential/native tests. No default dispatch change.
"""
import fcntl
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import time

R = Path('/root/results/afk-20261024-output-stores-repair')
FIRST = Path('/root/results/afk-20261024-direct-flow-repair')
SECOND = Path('/root/results/afk-20261024-dependency-repair')
LIB_HEAD = 'ff46a60610c45cf08faf5135e0605f897664a131'
BENCH_HEAD = '9a87ea3d69cc7c56c0c1b857ca0d4edc9525a4f1'


def main():
    deadline = time.monotonic() + 6 * 3600
    while True:
        if (SECOND / 'SKIPPED.txt').exists():
            R.mkdir(parents=True, exist_ok=False)
            (R / 'SKIPPED.txt').write_text('Previous dependent queue skipped; controls unresolved.\n')
            return
        if (SECOND / 'state.json').exists():
            state = json.loads((SECOND / 'state.json').read_text())
            if state.get('complete') or state.get('error'):
                break
        if time.monotonic() >= deadline:
            raise TimeoutError('previous queues have not completed in six hours')
        time.sleep(20)
    with open('/root/bench-native-afk.lock', 'a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        R.mkdir(parents=True, exist_ok=False)
        first = json.loads((FIRST / 'state.json').read_text())
        if not first.get('complete') or not first.get('controls_pass'):
            (R / 'SKIPPED.txt').write_text('Main queue controls unresolved.\n')
            return
        spec = importlib.util.spec_from_file_location('queue', '/root/run-afk-direct-flow-v2.py')
        q = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(q)
        q.R = R
        q.WT = Path('/root/BLAKE3-gpr-output-stores')
        q.BENCH = q.WT / 'bench-hashes'
        q.LIB_HEAD, q.BENCH_HEAD = LIB_HEAD, BENCH_HEAD
        q.PATCH = f'patch."https://github.com/johnservil/BLAKE3".blake3-servil.path="{q.WT}"'
        q.STATE = {'start':q.now(), 'complete':False, 'library':LIB_HEAD,
                   'bench':BENCH_HEAD, 'stages':[], 'main_controls':str(FIRST)}
        q.save()
        subprocess.run(['git','-C','/root/BLAKE3','fetch','-q','/root/gpr-output-stores.bundle',
                        'experiment/sam-gpr-output-stores'],check=True)
        subprocess.run(['git','-C','/root/BLAKE3','worktree','add','-q','--detach',str(q.WT),LIB_HEAD],check=True)
        subprocess.run(['git','clone','-q','-b','experiment/sam-direct-flow-calibration',
                        '/root/bench-direct-calibration.bundle',str(q.BENCH)],check=True)
        subprocess.run(['git','-C',str(q.BENCH),'remote','set-url','origin',
                        'https://github.com/samshackleton-tech/bench-hashes'],check=True)
        assert q.head(q.WT)==LIB_HEAD and q.head(q.BENCH)==BENCH_HEAD
        shutil.copy2(FIRST/'symbols.txt',R/'symbols.txt')
        (R/'lld').mkdir()
        (R/'lld/ld.lld').symlink_to((FIRST/'lld/ld.lld').resolve())
        env=q.ENV.copy(); env['BLAKE3_DIAGNOSTIC_GPR']='1'
        try:
            q.run(['gcc','-shared','-fPIC','-o',R/'abi.so',
                   q.WT/'c/blake3_gpr_chunk_root_x86-64_unix.S',
                   q.WT/'c/blake3_chunk_root_x86-64_unix.S','/root/gpr-abi.S'],
                  'tests/build-abi',cwd=R,timeout=60)
            q.run(['python3','/root/check-gpr-abi.py',R/'abi.so','--vary-output-offset'],'tests/abi',cwd=R,timeout=120)
            q.run(['cargo','nextest','run','--release','--lib','--tests','--no-fail-fast'],
                  'tests/library',cwd=q.WT,env=env,timeout=900)
            q.run(['cargo','--config',q.PATCH,'update','-q','-p','blake3-servil'],'setup/update')
            q.run(['cargo','nextest','run','--config',q.PATCH,'--release','--features','diag-direct-flow'],
                  'tests/bench',env=env,timeout=900)
            for producer, fill, old_name in [('words',False,'gpr-words'), ('fill',True,'gpr-fill')]:
                new=q.build_group('vector-output-'+producer,gpr=True,fill=fill)
                old=[FIRST/'bin'/old_name/f'bench-{i}' for i in range(16)]
                assert all(p.exists() for p in old)
                q.compare_groups('output-store-'+producer,old,new,'serial')
            q.STATE.update(complete=True,end=q.now());q.save()
            q.mark('Output-store experiment complete')
        except BaseException as error:
            q.STATE.update(error=repr(error),failed_at=q.now());q.save()
            raise


if __name__=='__main__':
    main()
