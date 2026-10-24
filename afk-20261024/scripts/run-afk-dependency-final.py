#!/usr/bin/env python3
"""Follow the main AFK queue: test whether inter-call dependency explains
64 B's reversal. Same direct word producer and in-place consumer, but the
next message's seed is independent of the preceding digest. Existing
bench-hashes comparisons; no custom timing or statistical implementation.
"""
import datetime
import fcntl
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import time

R = Path('/root/results/afk-20261024-dependency-final')
FIRST = Path('/root/results/afk-20261024-runtime-control')
BENCH_HEAD = 'e24c2df7bed714b28a3ba1847e84a9b6e7dc9324'


def main():
    # Wait for the repaired queue before requesting the native lock.
    deadline = time.monotonic() + 6 * 3600
    while True:
        if (FIRST / 'state.json').exists():
            state = json.loads((FIRST / 'state.json').read_text())
            if state.get('complete') or state.get('error'):
                break
        if time.monotonic() > deadline:
            raise TimeoutError('repaired queue has not finished')
        time.sleep(20)
    # Same lock as the first queue: no native jobs overlap.
    with open('/root/bench-native-afk.lock', 'a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        R.mkdir(parents=True, exist_ok=False)
        prior = json.loads((FIRST / 'state.json').read_text())
        if not prior.get('complete') or not prior.get('controls_pass'):
            (R / 'SKIPPED.txt').write_text('Main queue incomplete or controls failed; no dependent performance conclusion.\n')
            return
        spec = importlib.util.spec_from_file_location('queue', '/root/run-afk-direct-flow-v2.py')
        q = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(q)
        q.R = R
        q.BENCH_HEAD = BENCH_HEAD
        q.STATE = {'start': q.now(), 'complete': False, 'main_controls': str(FIRST),
                   'bench': BENCH_HEAD, 'library': q.LIB_HEAD, 'stages': []}
        q.save()
        assert q.head(q.WT) == q.LIB_HEAD
        assert q.head(q.BENCH) == prior['bench']
        shutil.move(str(q.BENCH), str(R / 'previous-benchmark-checkout'))
        subprocess.run(['git','clone','-q','-b','experiment/sam-direct-flow-dependency-v2',
                        '/root/bench-direct-independent-v2.bundle',str(q.BENCH)],check=True)
        subprocess.run(['git','-C',str(q.BENCH),'remote','set-url','origin',
                        'https://github.com/samshackleton-tech/bench-hashes'],check=True)
        assert q.head(q.BENCH) == BENCH_HEAD
        shutil.copy2(FIRST / 'symbols.txt', R / 'symbols.txt')
        (R / 'lld').mkdir()
        (R / 'lld/ld.lld').symlink_to((FIRST / 'lld/ld.lld').resolve())
        try:
            q.run(['cargo','--config',q.PATCH,'update','-q','-p','blake3-servil'],'setup/update')
            q.run(['cargo','nextest','run','--config',q.PATCH,'--release','--features','diag-direct-flow'],
                  'tests/independent',timeout=900)
            simd = q.build_group('simd-independent')
            gpr = q.build_group('gpr-independent',gpr=True)
            q.compare_groups('independent-gpr',simd,gpr,'serial')
            q.STATE.update(complete=True,end=q.now())
            q.save()
            q.mark('Dependency sensitivity complete')
        except BaseException as error:
            q.STATE.update(error=repr(error),failed_at=q.now())
            q.save()
            raise


if __name__ == '__main__':
    main()
