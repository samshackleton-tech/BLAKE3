import glob, csv, sys
r = sys.argv[1]
def mean(path):
    for l in open(path):
        f = l.rstrip('\n').split('\t')
        if len(f) > 5 and f[2] == 'ManyMessages' and f[3] == '64':
            v = [a.split('/') for a in f[5].split(',')]
            return sum(int(n) for n, u in v) / sum(int(u) for n, u in v)
for n in range(1, 15):
    d = f'{r}/run-{n}'
    s = glob.glob(d + '/benchmark-results/*/bench-hashes.samples.tsv')
    st = {row[2]: row[0] for row in csv.reader(open(d + '/stat.csv')) if len(row) > 3}
    print(f"run {n:2d} many64={mean(s[0]):5.1f} migrations={st.get('cpu-migrations')} cs={st.get('context-switches')} task-ms={float(st.get('task-clock', 0)):.0f}")
