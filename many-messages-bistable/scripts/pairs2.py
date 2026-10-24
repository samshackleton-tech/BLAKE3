import glob,sys
d=sys.argv[1]; cell=tuple(sys.argv[2].split('|'))
def mean(path):
    for l in open(path):
        f=l.rstrip('\n').split('\t')
        if tuple(f[:4])==cell:
            vals=[a.split('/') for a in f[5].split(',')]
            return sum(int(n) for n,u in vals)/sum(int(u) for n,u in vals)
for side in ('old','new'):
    fs=sorted(glob.glob(f'{d}/run-*-{side}.tsv'))
    print(side, ' '.join(f'{mean(f):.1f}' for f in fs))
