import json,subprocess,re,collections
H='@/home/samshackleton/work/.gh-auth-header'
def get(u, raw=False):
    args=['curl','-fsS','--max-time','60','-H',H]
    if raw: args+=['-H','Accept: application/vnd.github.raw','-r','0-6000']
    r=subprocess.run(args+['https://api.github.com/'+u],capture_output=True,text=True)
    return r.stdout if raw else json.loads(r.stdout)
rows=[]
for repo,branch in [('devonjonte/bench-hashes','main'),('johnservil/bench-hashes','main')]:
    t=get(f'repos/{repo}/git/trees/{branch}?recursive=1')
    for x in t['tree']:
        if x['path'].endswith('.samples.tsv'):
            h=get(f'repos/{repo}/contents/{x["path"]}?ref={branch}', raw=True)
            f=dict(re.findall(r'^# ([^:]+): (.*)$', h, re.M))
            rows.append((repo.split('/')[0], x['path'].split('/')[-2][:45], x['path'].split('/')[-1][:22], f.get('git commit','?')[:7], f.get('git clean status','?')[:12], f.get('dependency lock','?').split()[1][:10] if 'dependency lock' in f else '?', f.get('bench-hashes version','?')[:28]))
for r in sorted(rows): print(' | '.join(r))
