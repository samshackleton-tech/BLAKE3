import glob,sys
r=sys.argv[1]
def means(path):
    out={}
    for l in open(path):
        f=l.rstrip('\n').split('\t')
        if len(f)>5 and not l.startswith('#') and f[0]!='contender' and f[1]=='solo':
            v=[a.split('/') for a in f[5].split(',')]
            out[(f[0],f[2],f[3])]=sum(int(n) for n,u in v)/sum(int(u) for n,u in v)
    return out
m={c:means(glob.glob(f'{r}/cpu{c}/benchmark-results/*/bench-hashes.samples.tsv')[0]) for c in (0,1,2,3)}
for k in sorted(m[0]):
    print(f'{"|".join(k):45}', ' '.join(f'{m[c][k]:9.3f}' for c in (0,1,2,3)), f'  odd/even {((m[1][k]+m[3][k])/(m[0][k]+m[2][k])):.2f}')
