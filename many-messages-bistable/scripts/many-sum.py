import glob,os,sys
root=sys.argv[1]
def means(path):
    out={}
    for l in open(path):
        f=l.rstrip('\n').split('\t')
        if len(f)>5 and f[2]=='ManyMessages':
            vals=[a.split('/') for a in f[5].split(',')]
            out[(f[1],f[3])]=sum(int(n) for n,u in vals)/sum(int(u) for n,u in vals)
    return out
def key(p):
    b=os.path.basename(p); a,n=b.rsplit('-',1); return (a,int(n))
for d in sorted([d for d in glob.glob(root+'/*-*') if os.path.isdir(d)],key=key):
    s=glob.glob(d+'/benchmark-results/*/bench-hashes.samples.tsv')
    if not s: print(os.path.basename(d),'none'); continue
    m=means(s[0])
    print(f'{os.path.basename(d):8}', ' '.join(f'{sc}|{pt}={v:6.1f}' for (sc,pt),v in sorted(m.items())))
