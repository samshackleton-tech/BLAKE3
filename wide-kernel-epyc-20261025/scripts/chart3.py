#!/usr/bin/env python3
"""Every use case: new/old time for the two designs, wide kernel everywhere
(dotted) and calling threads only (solid), each contender's colour, from
data/three-way.json (three_way.py). Optional direct caller/everywhere runs
from a compare file. Writes OUT.html.

    chart3.py OUT.html [DIRECT.compare.out]
"""
import html, json, math, re, sys
from collections import defaultdict

SIZE = re.compile(r'^(\d+) (B|KiB|MiB|GiB)$')
MULT = {'B': 1, 'KiB': 1 << 10, 'MiB': 1 << 20, 'GiB': 1 << 30}
MSG = {'ManyMessages', 'IdleManyMessages', 'LentBatches', 'ContinuousBatches'}
COLOR = {'st': '#1f6fb4', 'mt': '#d9631e'}
NAMES = {'OneMessage': 'one message, after other work', 'IdleOneMessage': 'one message, after a pause',
         'ManyMessages': 'a batch of 64 B messages', 'IdleManyMessages': 'a batch, after a pause',
         'ContinuousMessages': 'a stream of messages', 'ContinuousBatches': 'a stream of batches',
         'LentMessages': 'messages, buffers lent', 'LentBatches': 'batches, buffers lent', 'MerkleTree': 'a Merkle tree'}
ORDER = ['OneMessage', 'IdleOneMessage', 'ContinuousMessages', 'LentMessages', 'ManyMessages', 'IdleManyMessages',
         'ContinuousBatches', 'LentBatches', 'MerkleTree']
LINE = re.compile(r'blake3-servil-(st|mt)\|(\w+)\|(\w+)\|(.+?): .* x([\d.]+) (\w+), (\d+) of')


def x_of(p):
    m = SIZE.match(p)
    return int(m[1]) * MULT[m[2]] if m else (int(p) if p.isdigit() else None)


def label(v, msgs):
    if msgs:
        return str(v)
    for u in ('GiB', 'MiB', 'KiB'):
        if v >= MULT[u] and v % MULT[u] == 0:
            return f'{v // MULT[u]} {u}'
    return f'{v} B'


def panel(title, series, msgs, direct, w=460, h=250):
    xs = [p[0] for pts in series.values() for p in pts]
    l, r, t, ph = 50, 12, 24, 170
    pw = w - l - r
    x0, x1 = math.log2(min(xs)), math.log2(max(xs))
    x1 = x1 if x1 > x0 else x0 + 1
    R0, R1 = 0.7, 1.15
    X = lambda v: l + (math.log2(v) - x0) / (x1 - x0) * pw
    Y = lambda v: t + ph - (min(max(v, R0), R1) - R0) / (R1 - R0) * ph
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" font-family="sans-serif" font-size="10">',
         f'<text x="{l}" y="14" font-size="12" font-weight="bold">{html.escape(title)}</text>',
         f'<rect x="{l}" y="{Y(1.03):.1f}" width="{pw}" height="{Y(0.97) - Y(1.03):.1f}" fill="#e8e8e8"/>',
         f'<rect x="{l}" y="{t}" width="{pw}" height="{ph}" fill="none" stroke="#999"/>',
         f'<line x1="{l}" x2="{l + pw}" y1="{Y(1):.1f}" y2="{Y(1):.1f}" stroke="#777" stroke-dasharray="2,2"/>']
    for v in (0.7, 0.8, 0.9, 1.0, 1.1):
        o.append(f'<text x="{l - 4}" y="{Y(v) + 3:.1f}" text-anchor="end">{v:.1f}</text>')
    o.append(f'<text x="12" y="{t + ph / 2:.0f}" transform="rotate(-90 12 {t + ph / 2:.0f})" text-anchor="middle" font-size="9">time against old (lower is faster)</text>')
    last = -1e9
    for v in sorted(set(xs)):
        if X(v) - last >= 40:
            last = X(v)
            o.append(f'<text x="{X(v):.1f}" y="{t + ph + 12}" text-anchor="middle">{html.escape(label(v, msgs))}</text>')
    for c, pts in series.items():
        for key, dash, wd in (('E', '2,3', 1.8), ('C', '', 2.2)):
            o.append(f'<polyline points="{" ".join(f"{X(p[0]):.1f},{Y(p[1][key]):.1f}" for p in pts)}" fill="none" stroke="{COLOR[c]}" stroke-width="{wd}" stroke-dasharray="{dash}"/>')
        for x, v, cell in pts:
            dv = direct.get(cell)
            if dv and dv[1] in ('slower', 'faster'):
                col = 'red' if dv[1] == 'slower' else 'green'
                tip = html.escape(f'{c} {label(x, msgs)}: caller-only judged {dv[1]} against everywhere, x{dv[0]:.3f}')
                o.append(f'<circle cx="{X(x):.1f}" cy="{Y(v["C"]):.1f}" r="3.4" fill="{col}" stroke="white"><title>{tip}</title></circle>')
    lx = 8
    for c, name in (('st', 'one thread'), ('mt', 'every thread')):
        for key, dash in (('E', '2,3'), ('C', '')):
            o.append(f'<line x1="{lx}" x2="{lx + 20}" y1="{h - 14}" y2="{h - 14}" stroke="{COLOR[c]}" stroke-width="2" stroke-dasharray="{dash}"/>')
            o.append(f'<text x="{lx + 23}" y="{h - 11}" font-size="9">{name}, {"everywhere" if key == "E" else "caller-only"}</text>')
            lx += 112
    o.append('</svg>')
    return '\n'.join(o)


def main():
    out = sys.argv[1]
    direct = {}
    if len(sys.argv) > 2:
        for m in map(LINE.match, open(sys.argv[2])):
            if m:
                direct[(m[1], m[2], m[3], m[4])] = (float(m[5]), m[6])
    cells = {tuple(k.split('|')): v for k, v in json.load(open('data/three-way.json')).items()}
    g = defaultdict(lambda: defaultdict(list))
    rest = []
    for k, v in cells.items():
        x = x_of(k[3])
        if x is None:
            rest.append((k, v))
        else:
            g[(k[2], k[1])][k[0]].append((x, v, k))
    panels = []
    for u in ORDER:
        for s in ('solo', 'shared'):
            if (u, s) in g:
                series = {c: sorted(g[(u, s)][c], key=lambda p: p[0]) for c in ('st', 'mt') if g[(u, s)][c]}
                if max(len(p) for p in series.values()) >= 3:
                    panels.append(panel(f'{NAMES.get(u, u)} ({s})', series, u in MSG, direct))
                else:
                    rest += [(p[2], p[1]) for pts in series.values() for p in pts]
    rows = ''.join(f'<tr><td>{k[0]}</td><td>{k[1]}</td><td>{html.escape(k[2])}</td><td>{html.escape(k[3])}</td><td>{v["E"]:.3f}</td><td>{v["C"]:.3f}</td><td>{v["CE"]:.3f}</td>'
                   f'<td>{(lambda d: f"x{d[0]:.3f} {d[1]}" if d else "")(direct.get(k))}</td></tr>' for k, v in sorted(rest))
    doc = f'''<!doctype html><meta charset="utf-8"><title>wide kernel: everywhere against calling threads only</title>
<style>body{{font-family:sans-serif;max-width:1440px;margin:auto;padding:1em}} .grid{{display:flex;flex-wrap:wrap;gap:6px}} table{{border-collapse:collapse;font-size:12px}} td,th{{border:1px solid #ccc;padding:2px 6px}}</style>
<h1>The wide AVX-512 kernel, two designs, every use case (EPYC 9255)</h1>
<p>Time against old (a9e70b8: candidate/release-0.8 + FANOUT 8); below 1 is faster. <b>Dotted: the wide kernel everywhere</b> (a49ff2c). <b>Solid: on calling threads only</b>, pool workers keeping the 16-input kernel (2cf9a56).
Each line is the geometric mean of two 12-pair <code>check</code> runs against old. The grey band is the check's 3% margin. Filled circles: cells the direct check (caller-only judged against everywhere, 12 relinked pairs) judged faster (green) or slower (red).
Warm small calls (64 B batches, small one-shots) move several percent between builds whatever the change (the same-code control read 0.93-1.06 there; bench-hashes #69's bistable cells), so differences under about 10% in those cells say nothing about the design.</p>
<div class="grid">{"".join(panels)}</div>
<h2>Collections and other cells</h2><table><tr><th>contender</th><th>scenario</th><th>use case</th><th>point</th><th>everywhere/old</th><th>caller/old</th><th>caller/everywhere</th><th>direct check</th></tr>{rows}</table>
'''
    open(out, 'w').write(doc)
    print(out, len(panels), 'panels')


if __name__ == '__main__':
    main()
