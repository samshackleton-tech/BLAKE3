"""Devon's run.py (BLAKE3 #183, data 2026-10-27/arm3-i7) on the EPYC 9255:
the same three builds and calls, pinned to CPU 2, AMD's user-space
instructions and cycles (no cpu_core/ prefix), 5 rounds rotating the builds."""
import subprocess, statistics
EXE = {'keep': '/root/arm3/keep/target-probe/release/examples/arm3_probe',
       'delete': '/root/arm3/delete/target-probe/release/examples/arm3_probe',
       'whole': '/root/arm3/whole/target-probe/release/examples/arm3_probe'}
rows = {}
for count in [3, 7, 19, 4, 8]:
    for length in [128, 256, 1024]:
        calls = 2_000_000 * 256 // (length * count) or 1
        for r in range(5):
            order = list(EXE)[r % 3:] + list(EXE)[:r % 3]
            for side in order:
                err = subprocess.run(['taskset', '-c', '2', 'perf', 'stat', '-x,', '-e', 'instructions:u,cycles:u', '--',
                                      EXE[side], str(count), str(length), str(calls)], capture_output=True, text=True).stderr
                v = [int(l.split(',')[0]) for l in err.splitlines() if l and l.split(',')[0].isdigit()]
                rows.setdefault((count, length, side), []).append((v[0] / calls, v[1] / calls))
print('count  len  build    instructions/call  cycles/call (median)  x keep')
for count in [3, 7, 19, 4, 8]:
    for length in [128, 256, 1024]:
        keep = statistics.median(c for _, c in rows[(count, length, 'keep')])
        for side in EXE:
            v = rows[(count, length, side)]
            cyc = statistics.median(c for _, c in v)
            print(f'{count:5} {length:4}  {side:7} {statistics.median(i for i, _ in v):12.0f}  {cyc:12.0f}  x{cyc / keep:.3f}')
