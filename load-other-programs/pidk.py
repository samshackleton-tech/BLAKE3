import sys,collections,datetime
start=datetime.datetime.strptime(sys.argv[2],'%H:%M:%S')
tot=collections.Counter(); sec=collections.Counter()
for l in open(sys.argv[1]):
    f=l.split()
    if len(f)<10 or not f[0][:2].isdigit(): continue
    try: cpu=float(f[7])
    except: continue
    c=f[9]
    if c.startswith('kworker') or c.startswith('kswapd') or c.startswith('ksoftirq') or c.startswith('rcu') or c.startswith('jbd2') or c.startswith('md'):
        kind=c.split('/')[0] + ('-'+c.split('-',1)[1] if '-' in c else '')
        tot[kind]+=cpu
        sec[int((datetime.datetime.strptime(f[0],'%H:%M:%S')-start).total_seconds())]+=cpu
for k,v in tot.most_common(8): print(f'{v/100:7.2f} cpu-s {k}')
print('seconds with kernel-thread CPU >= 60%:', sorted((s,round(v)) for s,v in sec.items() if v>=60))
