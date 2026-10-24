import json,subprocess,re
H='@/home/samshackleton/work/.gh-auth-header'
def raw(repo,path):
    return subprocess.run(['curl','-fsS','--max-time','60','-H',H,'-H','Accept: application/vnd.github.raw','-r','0-12000',f'https://api.github.com/repos/{repo}/contents/{path}?ref=main'],capture_output=True,text=True).stdout
for path in ['benchmark-results/AppleM4Max.darwin25/b3sum.samples.tsv','benchmark-results/AppleM4Max.darwin25/bench-hashes.samples.tsv','benchmark-results/aarch64.linux618520virt/b3sum.samples.tsv','benchmark-results/aarch64.linux618520virt/bench-hashes.samples.tsv']:
    h=raw('johnservil/bench-hashes',path)
    print('=====',path)
    for l in h.splitlines():
        if l.startswith('#') and re.search(r'servil|clocks|lock|clean|commit|source', l, re.I) and not l.startswith('# contender'):
            print('  ',l[:260])
