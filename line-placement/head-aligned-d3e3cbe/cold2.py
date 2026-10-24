import glob,sys,collections,statistics
res=collections.defaultdict(list)
for d in sorted(glob.glob(sys.argv[1]+'/*-*')):
    name=d.rsplit('/',1)[1].rsplit('-',1)[0]
    s=glob.glob(d+'/benchmark-results/*/bench-hashes.samples.tsv')
    for l in open(s[0]):
        f=l.rstrip('\n').split('\t')
        if len(f)>5 and f[1]=='solo' and f[2] in ('OneMessage','LentMessages'):
            v=[a.split('/') for a in f[5].split(',')]
            res[(f[2],f[3],f[0],name)].append(sum(int(u) for n,u in v)/sum(int(n) for n,u in v))
for k in sorted(res): print(f'{k[0]:12} {k[1]:6} {k[2]:18} {k[3]:5} median {statistics.median(res[k]):.3f} GB/s  ({" ".join(f"{x:.3f}" for x in res[k])})')
