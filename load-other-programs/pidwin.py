import sys,collections,datetime
start=datetime.datetime.strptime(sys.argv[2],'%H:%M:%S')
wins=[float(x) for x in sys.argv[3].split(',')]
by=collections.defaultdict(list)
for l in open(sys.argv[1]):
    f=l.split()
    if len(f)<10 or not f[0][:2].isdigit(): continue
    try: cpu=float(f[7])
    except: continue
    t=(datetime.datetime.strptime(f[0],'%H:%M:%S')-start).total_seconds()
    if cpu>=5: by[int(t)].append((cpu,f[9].split('/')[-1]))
for w in wins:
    for s in (int(w), int(w)+1):
        print(f'{w:6.1f} s+{s-int(w)}:', sorted(by.get(s,[]),reverse=True)[:4])
