"""Deterministic fixtures for release-check.py; NOT a real release verdict."""
import contextlib,importlib.util,io,json,os,pathlib,tempfile
from unittest.mock import patch
repo=pathlib.Path('/home/samshackleton/work/BLAKE3-current-john')
os.chdir(repo)
spec=importlib.util.spec_from_file_location('release_check',repo/'tools/release-check.py')
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
HEAD='a'*40; OLD='b'*40

def fake_git(*args):
    if args[0]=='rev-parse': return HEAD if args[1]=='candidate' else OLD
    if args[0]=='tag': return 'v0.3.0+fixture'
    if args[0]=='diff': return 'README.md\nQUALITY.md\nCHANGELOG.md'
    raise AssertionError(args)

results=[]
for scenario,ci_skipped,all_cells in [('positive control',False,True),('CI jobs skipped',True,True),('Mac changed-cells only',False,False)]:
    with tempfile.TemporaryDirectory() as tmp:
        root=pathlib.Path(tmp)
        (root/'runner/jobs').mkdir(parents=True)
        (root/'runner/results/1').mkdir(parents=True)
        job={'type':'check','old_commit':OLD,'new_commit':HEAD,'bench_commit':'c'*40}
        if all_cells: job['cells']='all'
        (root/'runner/jobs/job.json').write_text(json.dumps(job))
        (root/'runner/results/1/verdict.json').write_text(json.dumps({'job':'job.json','status':'no regression'}))
        requests=[]
        def github(path):
            requests.append(path)
            if '/actions/runs?' in path: return {'workflow_runs':[{'id':1,'name':'tests','status':'completed','conclusion':'success'}]}
            if '/actions/runs/1/jobs' in path: return {'total_count':2,'jobs':[{'name':'rustfmt','conclusion':'success'},{'name':'Linux GNU stable','conclusion':'skipped' if ci_skipped else 'success'}]}
            if path.endswith('/statuses'): return [{'context':'long proofs','state':'success'}]
            raise AssertionError(path)
        output=io.StringIO()
        with patch.object(module,'MAIN',tmp),patch.object(module,'git',fake_git),patch.object(module,'github',github),patch.object(module,'log_ends_with',lambda *a: True),patch('sys.argv',['release-check.py','candidate']),contextlib.redirect_stdout(output):
            try: module.main()
            except SystemExit as e: code=e.code
        results.append({'fixture':scenario,'expected_release_pass':scenario=='positive control','actual_exit':code,'requests':requests,'output':output.getvalue()})
        assert code==0, 'the reproduction targets the existing false-pass behavior'
path=pathlib.Path('/home/samshackleton/blake3-reports/release/gate-gap-fixtures.json')
path.write_text(json.dumps(results,indent=2)+'\n')
for result in results:
    print(result['fixture'], 'expected pass:',result['expected_release_pass'],'actual exit:',result['actual_exit'])
print('Fixture results only; no real release gates were run.')
