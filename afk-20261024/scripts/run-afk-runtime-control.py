#!/usr/bin/env python3
"""Third control attempt: runtime off/on in the SAME plant-capable code.
Preserves earlier attempts. Same-length environment values and wrapper paths;
A/A inactive first, then one-cell active control, then ordinary implementation
comparisons with the plant feature absent. Uses the established queue helpers.
"""
import fcntl
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess

R=Path('/root/results/afk-20261024-runtime-control')
HEAD='84248f33eb0a8d196e8e17a68acc711f4a5c641f'
FIRST=Path('/root/results/afk-20261024-direct-flow')


def main():
    with open('/root/bench-native-afk.lock','a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        R.mkdir(parents=True,exist_ok=False)
        spec=importlib.util.spec_from_file_location('queue','/root/run-afk-direct-flow-v2.py')
        q=importlib.util.module_from_spec(spec);spec.loader.exec_module(q)
        q.R=R;q.BENCH_HEAD=HEAD
        q.ENV['DIAG_DIRECT_PLANT_ACTIVE']='1'  # required by plant tests/build smoke
        assert q.head(q.WT)==q.LIB_HEAD
        assert q.head(q.BENCH)=='9a87ea3d69cc7c56c0c1b857ca0d4edc9525a4f1'
        shutil.move(str(q.BENCH),str(R/'previous-benchmark-checkout'))
        subprocess.run(['git','clone','-q','-b','experiment/sam-direct-flow-calibration-v2',
                        '/root/bench-direct-runtime-plant.bundle',str(q.BENCH)],check=True)
        subprocess.run(['git','-C',str(q.BENCH),'remote','set-url','origin',
                        'https://github.com/samshackleton-tech/bench-hashes'],check=True)
        assert q.head(q.BENCH)==HEAD
        q.STATE={'start':q.now(),'complete':False,'controls_pass':None,'stages':[],
                 'library':q.LIB_HEAD,'bench':HEAD,
                 'previous_attempts':[str(FIRST),'/root/results/afk-20261024-direct-flow-repair']}
        q.save()
        shutil.copy2(FIRST/'symbols.txt',R/'symbols.txt')
        (R/'lld').mkdir();(R/'lld/ld.lld').symlink_to((FIRST/'lld/ld.lld').resolve())

        def wrappers(name,bins,active):
            folder=R/'activation'/name;folder.mkdir(parents=True)
            result=[]
            for i,binary in enumerate(bins):
                p=folder/f'bench-{i}.sh'
                p.write_text(f'#!/bin/sh\nexec env DIAG_DIRECT_PLANT_ACTIVE={int(active)} {binary} "$@"\n')
                p.chmod(0o755);result.append(p)
            return result

        def check_headers(name,family,old_active,new_active):
            folder=R/name/family/'samples'
            for side,active in [('old',old_active),('new',new_active)]:
                files=list(folder.glob(f'run-*-{side}.tsv'))
                assert len(files)==16,files
                for p in files:
                    h=p.read_text()
                    assert '# experiment plant:' in h
                    assert f'# experiment plant active: {str(active).lower()}' in h,p

        try:
            q.run(['cargo','--config',q.PATCH,'update','-q','-p','blake3-servil'],'setup/update')
            for label,feature in [('plain','diag-direct-flow'),('plant','diag-direct-plant'),('fill','diag-direct-fill')]:
                q.run(['cargo','nextest','run','--config',q.PATCH,'--release','--features',feature],f'tests/{label}',timeout=900)
            a=q.build_group('control-a',plant=True)
            b=q.build_group('control-b',plant=True)
            a0=wrappers('old-zero',a,False)
            b0=wrappers('new-zero',b,False)
            b1=wrappers('new-one1',b,True)  # same path length as new-zero
            aa=[]
            for family in q.POINTS:
                aa.append(q.compare_groups('aa-inactive',a0,b0,family))
                check_headers('aa-inactive',family,False,False)
            positive=q.compare_groups('plant-active',a0,b1,'serial')
            check_headers('plant-active','serial',False,True)
            aa_pass=all(o['exit']==0 and not o['slower'] for o in aa)
            plant_pass=positive['exit']==1 and positive['slower']==[q.PLANTED_CELL]
            q.STATE.update(aa_pass=aa_pass,plant_pass=plant_pass,controls_pass=aa_pass and plant_pass)
            q.save()
            if q.STATE['controls_pass']:
                baseline=q.build_group('simd-words')
                gpr=q.build_group('gpr-words',gpr=True)
                for family in q.POINTS:
                    q.compare_groups('gpr-words',baseline,gpr,family)
                fill_simd=q.build_group('simd-fill',fill=True)
                fill_gpr=q.build_group('gpr-fill',gpr=True,fill=True)
                for family in q.POINTS:
                    q.compare_groups('gpr-fill',fill_simd,fill_gpr,family)
            else:
                q.mark('BLOCKED: runtime control criteria not met; no implementation comparisons')
            q.STATE.update(complete=True,end=q.now());q.save()
            q.mark('Runtime-control queue complete')
        except BaseException as error:
            q.STATE.update(error=repr(error),failed_at=q.now());q.save();raise


if __name__=='__main__':
    main()
