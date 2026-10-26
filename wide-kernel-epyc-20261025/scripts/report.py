#!/usr/bin/env python3
"""Draw the wide-kernel comparison: one panel per use case and scenario,
throughput against input size, old dashed and new solid, with the new/old
time ratio underneath, from `bench-hashes compare` outputs (one or more
independent runs; a cell's figure is the geometric mean over the runs).
Writes a self-contained HTML page with inline SVG.

    report.py OUT.html TITLE [--extra EXTRA.html] RUN.compare.out [RUN.compare.out ...]
"""
import html, math, re, sys
from collections import defaultdict

LINE = re.compile(r'(?P<c>blake3-servil-(?:st|mt))\|(?P<s>\w+)\|(?P<u>\w+)\|(?P<p>.+?): (?P<a>[\d.]+) -> (?P<b>[\d.]+) ns/unit\s+x(?P<r>[\d.]+) (?P<v>\w+), (?P<f>\d+) of (?P<n>\d+) pairs faster')
MSG_UNITS = {'ManyMessages', 'IdleManyMessages', 'LentBatches', 'ContinuousBatches'}
SIZE = re.compile(r'^(\d+) (B|KiB|MiB|GiB)$')
MULT = {'B': 1, 'KiB': 1 << 10, 'MiB': 1 << 20, 'GiB': 1 << 30}
COLOR = {'blake3-servil-st': '#1f6fb4', 'blake3-servil-mt': '#d9631e'}
LABEL = {'blake3-servil-st': 'one thread', 'blake3-servil-mt': 'every thread'}
NAMES = {'OneMessage': 'one message, after other work', 'IdleOneMessage': 'one message, after a pause',
         'ManyMessages': 'a batch of 64 B messages, after other work', 'IdleManyMessages': 'a batch of 64 B messages, after a pause',
         'ContinuousMessages': 'messages nonstop (a stream)', 'ContinuousBatches': 'batches nonstop (a stream)',
         'LentMessages': 'messages, buffers lent', 'LentBatches': 'batches, buffers lent', 'MerkleTree': 'a Merkle tree, by leaves'}
ORDER = ['OneMessage', 'IdleOneMessage', 'ManyMessages', 'IdleManyMessages', 'ContinuousMessages', 'ContinuousBatches',
         'LentMessages', 'LentBatches', 'MerkleTree']


def x_of(point):
    m = SIZE.match(point)
    if m:
        return int(m.group(1)) * MULT[m.group(2)]
    return int(point) if point.isdigit() else None


def load(paths):
    runs = []
    for path in paths:
        cells = {}
        for line in open(path):
            m = LINE.match(line)
            if m:
                cells[(m['c'], m['s'], m['u'], m['p'])] = (float(m['a']), float(m['b']), float(m['r']), m['v'], int(m['f']), int(m['n']))
        runs.append(cells)
    keys = set.intersection(*(set(r) for r in runs))
    gm = lambda vals: math.exp(sum(math.log(v) for v in vals) / len(vals))
    merged = {k: dict(old=gm([r[k][0] for r in runs]), new=gm([r[k][1] for r in runs]), ratio=gm([r[k][2] for r in runs]),
                      ratios=[r[k][2] for r in runs], verdicts=[r[k][3] for r in runs], faster=[r[k][4] for r in runs], pairs=[r[k][5] for r in runs])
              for k in keys}
    return merged, len(runs)


def fmt_x(v, msgs):
    if msgs:
        return str(v)
    for unit in ('GiB', 'MiB', 'KiB'):
        if v >= MULT[unit] and v % MULT[unit] == 0:
            return f'{v // MULT[unit]} {unit}'
    return f'{v} B'


def panel(title, series, msgs, w=460, h=372):
    """series: contender -> sorted [(x, old_tp, new_tp, ratio, verdicts)]."""
    xs = [p[0] for s in series.values() for p in s]
    ys = [y for s in series.values() for p in s for y in (p[1], p[2])]
    l, r, t = 58, 14, 26
    pw, ph = w - l - r, 196
    rt, rh = t + ph + 14, 72
    x0, x1 = math.log2(min(xs)), math.log2(max(xs))
    x1 = x1 if x1 > x0 else x0 + 1
    y0, y1 = math.log10(min(ys)) - 0.05, math.log10(max(ys)) + 0.05
    X = lambda v: l + (math.log2(v) - x0) / (x1 - x0) * pw
    Y = lambda v: t + ph - (math.log10(v) - y0) / (y1 - y0) * ph
    R0, R1 = 0.7, 1.3
    RY = lambda v: rt + rh - (min(max(v, R0), R1) - R0) / (R1 - R0) * rh
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" font-family="sans-serif" font-size="10">',
         f'<text x="{l}" y="15" font-size="12" font-weight="bold">{html.escape(title)}</text>',
         f'<rect x="{l}" y="{t}" width="{pw}" height="{ph}" fill="none" stroke="#999"/>',
         f'<rect x="{l}" y="{RY(1.03):.1f}" width="{pw}" height="{RY(0.97) - RY(1.03):.1f}" fill="#e8e8e8"/>',
         f'<rect x="{l}" y="{rt}" width="{pw}" height="{rh}" fill="none" stroke="#999"/>',
         f'<line x1="{l}" x2="{l + pw}" y1="{RY(1):.1f}" y2="{RY(1):.1f}" stroke="#777" stroke-dasharray="2,2"/>']
    for v in (0.8, 0.9, 1.0, 1.1, 1.2):
        o.append(f'<text x="{l - 4}" y="{RY(v) + 3:.1f}" text-anchor="end" font-size="8.5">{v:.1f}</text>')
    o.append(f'<text x="14" y="{rt + rh / 2:.0f}" transform="rotate(-90 14 {rt + rh / 2:.0f})" text-anchor="middle" font-size="9">new/old time</text>')
    for e in range(math.floor(y0), math.ceil(y1) + 1):
        for m in (1, 2, 5):
            v = m * 10 ** e
            if y0 <= math.log10(v) <= y1:
                o.append(f'<line x1="{l}" x2="{l + pw}" y1="{Y(v):.1f}" y2="{Y(v):.1f}" stroke="#eee"/>')
                o.append(f'<text x="{l - 4}" y="{Y(v) + 3:.1f}" text-anchor="end">{v:g}</text>')
    last = -1e9
    for v in sorted(set(xs)):
        xx = X(v)
        if xx - last < 40:
            continue
        last = xx
        o.append(f'<line x1="{xx:.1f}" x2="{xx:.1f}" y1="{t}" y2="{rt + rh}" stroke="#f0f0f0"/>')
        o.append(f'<text x="{xx:.1f}" y="{rt + rh + 12}" text-anchor="middle">{html.escape(fmt_x(v, msgs))}</text>')
    unit = 'million messages/s' if msgs else 'GB/s'
    o.append(f'<text x="14" y="{t + ph / 2:.0f}" transform="rotate(-90 14 {t + ph / 2:.0f})" text-anchor="middle">{unit}, higher is faster</text>')
    for c, pts in series.items():
        for side, dash, width in (('old', '6,4', 1.6), ('new', '', 2.2)):
            idx = 1 if side == 'old' else 2
            o.append(f'<polyline points="{" ".join(f"{X(p[0]):.1f},{Y(p[idx]):.1f}" for p in pts)}" fill="none" stroke="{COLOR[c]}" stroke-width="{width}" stroke-dasharray="{dash}"/>')
        o.append(f'<polyline points="{" ".join(f"{X(p[0]):.1f},{RY(p[3]):.1f}" for p in pts)}" fill="none" stroke="{COLOR[c]}" stroke-width="1.6"/>')
        for p in pts:
            if 'slower' in p[4] or 'faster' in p[4]:
                mark = 'red' if 'slower' in p[4] else 'green'
                tip = html.escape(f'{LABEL[c]}, {fmt_x(p[0], msgs)}: x{p[3]:.3f}, judged {"/".join(p[4])}')
                for cy in (Y(p[2]), RY(p[3])):
                    o.append(f'<circle cx="{X(p[0]):.1f}" cy="{cy:.1f}" r="3.3" fill="{mark}" stroke="white" stroke-width="0.8"><title>{tip}</title></circle>')
    lx, lg = 18, h - 8
    for c in series:
        for side, dash in (('old', '6,4'), ('new', '')):
            o.append(f'<line x1="{lx}" x2="{lx + 20}" y1="{lg}" y2="{lg}" stroke="{COLOR[c]}" stroke-width="2" stroke-dasharray="{dash}"/>')
            o.append(f'<text x="{lx + 23}" y="{lg + 3}" font-size="9">{LABEL[c]}, {side}</text>')
            lx += 110
    o.append('</svg>')
    return '\n'.join(o)


def main():
    args = sys.argv[1:]
    out_path, title = args[0], args[1]
    rest = args[2:]
    extra = ''
    if rest and rest[0] == '--extra':
        extra = open(rest[1]).read()
        rest = rest[2:]
    cells, nruns = load(rest)
    groups = defaultdict(lambda: defaultdict(list))
    other = []
    for (c, s, u, p), v in cells.items():
        x = x_of(p)
        if x is None:
            other.append(((c, s, u, p), v))
            continue
        k = 1e3 if u in MSG_UNITS else 1.0  # 1/ns: GB/s per byte; x1e3: million messages/s
        groups[(u, s)][c].append((x, k / v['old'], k / v['new'], v['ratio'], v['verdicts'], p, v))
    panels = []
    for u in ORDER + sorted({g[0] for g in groups} - set(ORDER)):
        for s in ('solo', 'shared'):
            if (u, s) not in groups:
                continue
            series = {c: sorted(groups[(u, s)][c]) for c in COLOR if groups[(u, s)][c]}
            if max(len(v) for v in series.values()) < 3:
                other += [((c, s, u, pt[5]), pt[6]) for c, pts in series.items() for pt in pts]
                continue
            panels.append(panel(f'{NAMES.get(u, u)} ({s})', series, u in MSG_UNITS))
    verdicts = defaultdict(int)
    for v in cells.values():
        for x in v['verdicts']:
            verdicts[x] += 1
    row = lambda k, v: (f'<tr><td>{html.escape(k[0].replace("blake3-servil-", ""))}</td><td>{k[1]}</td><td>{html.escape(k[2])}</td><td>{html.escape(k[3])}</td>'
                        f'<td>{v["ratio"]:.3f}</td><td>{" / ".join(f"{r:.3f}" for r in v["ratios"])}</td><td>{" / ".join(v["verdicts"])}</td>'
                        f'<td>{" / ".join(f"{a} of {b}" for a, b in zip(v["faster"], v["pairs"]))}</td></tr>')
    head = '<tr><th>contender</th><th>scenario</th><th>use case</th><th>point</th><th>new/old (mean of runs)</th><th>each run</th><th>verdicts</th><th>pairs faster</th></tr>'
    judged = ''.join(row(k, v) for k, v in sorted(cells.items(), key=lambda kv: kv[1]['ratio']) if 'slower' in v['verdicts'] or 'faster' in v['verdicts'])
    cat = ''.join(row(k, v) for k, v in sorted(other))
    doc = f'''<!doctype html><meta charset="utf-8"><title>{html.escape(title)}</title>
<style>body{{font-family:sans-serif;max-width:1440px;margin:auto;padding:1em}} .grid{{display:flex;flex-wrap:wrap;gap:6px}}
table{{border-collapse:collapse;font-size:12px;margin:.5em 0}} td,th{{border:1px solid #ccc;padding:2px 6px;vertical-align:top}}</style>
<h1>{html.escape(title)}</h1>
<p><b>Dashed: old</b> (without the wide kernel). <b>Solid: new</b> (with it). Blue: one thread (blake3-servil-st); orange: every thread (blake3-servil-mt).
Each point is the geometric mean over {nruns} independent run(s) of <code>bench-hashes check</code> (12 relinked layouts a side a run).
Under each panel: new/old time, below 1 faster; the grey band is the check's 3% margin. Filled circles mark cells the check judged
faster (green) or slower (red) in at least one run's first stage.</p>
<p>Verdicts over all cells and runs: {", ".join(f"{k} {n}" for k, n in sorted(verdicts.items()))}.</p>
{extra}
<div class="grid">{"".join(panels)}</div>
<h2>Every cell judged faster or slower</h2><table>{head}{judged}</table>
<h2>Collections and other cells not drawn</h2><table>{head}{cat}</table>
'''
    open(out_path, 'w').write(doc)
    print(f'{out_path}: {len(cells)} cells, {len(panels)} panels, {nruns} runs; verdicts {dict(verdicts)}')


if __name__ == '__main__':
    main()
