#!/usr/bin/env python3
"""Preserve the invalid plant run; reuse the valid A/A controls and baseline
layouts. Correct the missing plant=True invocation, assert the runtime header,
then proceed only if exactly the intended cell is detected.
"""
import fcntl
import importlib.util
import json
from pathlib import Path
import shutil

R = Path('/root/results/afk-20261024-direct-flow-repair')
FIRST = Path('/root/results/afk-20261024-direct-flow')


def main():
    with open('/root/bench-native-afk.lock', 'a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        prior = json.loads((FIRST/'state.json').read_text())
        assert prior['complete'] and prior['aa_pass'], 'A/A must have completed successfully'
        wrong = json.loads((FIRST/'bin/plant/manifest.json').read_text())
        assert 'diag-direct-plant' not in wrong['features'], 'repair is specific to the missing feature invocation'
        R.mkdir(parents=True,exist_ok=False)
        spec=importlib.util.spec_from_file_location('queue','/root/run-afk-direct-flow-v2.py')
        q=importlib.util.module_from_spec(spec);spec.loader.exec_module(q)
        q.R=R
        assert q.head(q.WT)==q.LIB_HEAD and q.head(q.BENCH)==q.BENCH_HEAD
        q.STATE={'start':q.now(),'complete':False,'controls_pass':None,'aa_pass':True,
                 'inherited_aa':str(FIRST/'aa'),'invalid_control':str(FIRST/'plant'),
                 'library':q.LIB_HEAD,'bench':q.BENCH_HEAD,'stages':[]}
        q.save()
        shutil.copy2(FIRST/'symbols.txt',R/'symbols.txt')
        (R/'lld').mkdir();(R/'lld/ld.lld').symlink_to((FIRST/'lld/ld.lld').resolve())
        baseline=[FIRST/'bin/simd-a'/f'bench-{i}' for i in range(16)]
        try:
            plant=q.build_group('plant-enabled',plant=True)
            positive=q.compare_groups('plant-enabled',baseline,plant,'serial')
            passed=positive['exit']==1 and positive['slower']==[q.PLANTED_CELL]
            q.STATE['plant_pass']=passed;q.STATE['controls_pass']=passed;q.save()
            if passed:
                word_gpr=q.build_group('gpr-words',gpr=True)
                for family in q.POINTS:
                    q.compare_groups('gpr-words',baseline,word_gpr,family)
                fill_simd=q.build_group('simd-fill',fill=True)
                fill_gpr=q.build_group('gpr-fill',gpr=True,fill=True)
                for family in q.POINTS:
                    q.compare_groups('gpr-fill',fill_simd,fill_gpr,family)
            else:
                q.mark('BLOCKED: corrected positive control did not meet its declared criterion')
            q.STATE.update(complete=True,end=q.now());q.save()
            q.mark('Repaired queue complete')
        except BaseException as error:
            q.STATE.update(error=repr(error),failed_at=q.now());q.save();raise


if __name__=='__main__':
    main()
