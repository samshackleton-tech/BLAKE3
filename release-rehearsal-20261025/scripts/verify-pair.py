"""Verify both staged archives, including the CLI's exact library checksum."""
import hashlib,json,pathlib,subprocess,sys,tarfile,tomllib
r=pathlib.Path(sys.argv[1]);artifacts=r/'paired-artifacts'
library,=artifacts.glob('blake3-servil-*.crate');cli,=artifacts.glob('b3sums-*.crate')
expected=json.loads((r/'result.json').read_text());version=expected['all_version_fields'];commit=expected['local_version_commit']
def contents(archive,path):
 with tarfile.open(archive) as t:
  name,=[m for m in t.getmembers() if m.isfile() and m.name.split('/',1)[1]==path]
  return t.extractfile(name).read().decode()
for archive in [library,cli]:
 manifest=tomllib.loads(contents(archive,'Cargo.toml'))
 assert manifest['package']['version']==version,archive
 vcs=json.loads(contents(archive,'.cargo_vcs_info.json'))
 assert vcs['git']['sha1']==commit and not vcs['git'].get('dirty',False),vcs
lock=tomllib.loads(contents(cli,'Cargo.lock'))
dep,=[p for p in lock['package'] if p['name']=='blake3-servil']
assert dep['version']==version,dep
assert dep['source']=='registry+https://github.com/rust-lang/crates.io-index',dep
sha=hashlib.sha256(library.read_bytes()).hexdigest()
assert dep['checksum']==sha,(dep['checksum'],sha)
b3=subprocess.check_output(['/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0',str(library)],text=True).split()[0]
result={'rehearsal_only':True,'commit':commit,'version':version,'library':library.name,'cli':cli.name,'cli_lock_matches_exact_library_archive':True,'library_sha256':sha,'library_blake3':b3,'published':False}
(r/'paired-result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
