import sys
path=sys.argv[1]; wins=[tuple(map(float,w.split('-'))) for w in sys.argv[2].split(',')]
runs=[]
for l in open(path):
    if l.startswith('#') or l.startswith('contender'): continue
    f=l.rstrip('\n').split('\t')
    ns=[int(x.split('/')[0]) for x in f[5].split(',')]
    st=[int(x) for x in f[6].split(',')]
    for s,n in zip(st,ns): runs.append((s/1000, s/1000+n/1e9, f[0], f[1], f[3]))
for a,b in wins:
    hit=[(r[2],r[3],r[4],round(r[1]-r[0],2)) for r in runs if r[0]<b and r[1]>a]
    longest=sorted(hit,key=lambda x:-x[3])[:3]
    print(f'{a:6.1f}-{b:6.1f}: {len(hit)} runs; longest {longest}')
