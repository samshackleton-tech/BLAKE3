"""Verify gen-ver's version-only tree in an isolated rehearsal clone."""
import copy,json,pathlib,subprocess,sys,tomllib
root=pathlib.Path(sys.argv[1]);repo=root/'checkout'
def git(*args):return subprocess.check_output(['git','-C',str(repo),*args],text=True).strip()
def before(path):return subprocess.check_output(['git','-C',str(repo),'show','HEAD^:'+path],text=True)
parent=git('rev-parse','HEAD^');head=git('rev-parse','HEAD')
assert parent=='3d67a0d75d5a83ff6c2d0f5660e8d3216a3504e4'
full='0.8.0+'+parent
tag='v'+full
assert git('rev-parse',tag)==head
expected={'Cargo.toml','b3sum/Cargo.toml','b3sum/Cargo.lock','capi/Cargo.toml','capi/b3.h','CHANGELOG.md'}
changed=set(git('diff','--name-only','HEAD^','HEAD').splitlines())
assert changed==expected,changed
for path in ['Cargo.toml','b3sum/Cargo.toml','capi/Cargo.toml']:
 old=tomllib.loads(before(path));new=tomllib.loads((repo/path).read_text())
 want=copy.deepcopy(old);want['package']['version']=full
 if path.startswith('b3sum/'):
  want['dependencies']['blake3']['version']='='+full
 assert new==want,path
old=tomllib.loads(before('b3sum/Cargo.lock'));new=tomllib.loads((repo/'b3sum/Cargo.lock').read_text())
want=copy.deepcopy(old)
for package in want['package']:
 if package['name'] in ['blake3-servil','b3sums']:package['version']=full
assert new==want,'Cargo.lock changed beyond the two package versions'
old_header=before('capi/b3.h');old_capi=tomllib.loads(before('capi/Cargo.toml'))['package']['version']
assert (repo/'capi/b3.h').read_text()==old_header.replace('#define B3_VERSION "'+old_capi+'"','#define B3_VERSION "'+full+'"')
old=before('CHANGELOG.md').splitlines();new=(repo/'CHANGELOG.md').read_text().splitlines()
assert new[0].startswith('# blake3-servil '+full) and new[1:]==old[1:]
# This is the current release-check.py selection, not a real release verdict.
selected=git('tag','--list','v*','--sort=-creatordate').splitlines()[0]
selection_is_candidate=git('rev-parse',selected+'^{commit}')==head
result={'rehearsal_only':True,'code_commit':parent,'local_version_commit':head,'local_tag':tag,'all_version_fields':full,'changed_paths':sorted(changed),'lock_changed_only_versions':True,'current_checker_previous_tag':selected,'current_checker_selects_candidate_as_previous':selection_is_candidate,'production_published':False}
(root/'result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
