#!/usr/bin/env python3
"""Static assembly audit of the experiment's producer, consumer and dispatch.
No timing. Keep complete disassembly and print call/store summaries."""
import pathlib
import re
import subprocess
import sys

exe, dest = sys.argv[1:]
rows = subprocess.run(['nm', '-C', '-S', '--defined-only', exe], check=True, capture_output=True, text=True).stdout
texts = []
for row in rows.splitlines():
    p = row.split(None, 3)
    if len(p) != 4 or 'bench_hashes::direct_flow' not in p[3]:
        continue
    a, n = int(p[0], 16), int(p[1], 16)
    dis = subprocess.run(['objdump', '-d', '-C', '--no-show-raw-insn', f'--start-address={a}', f'--stop-address={a+n}', exe], check=True, capture_output=True, text=True).stdout
    texts.append(dis)
    print(p[3], 'bytes', n)
    for line in dis.splitlines():
        if re.search(r'call.*(memcpy|memmove|hash_serial|hash_many)|\bmov[a-z]*\s+%[^,]+,\(?0?x?[0-9a-f]*\(%[a-z0-9]+', line):
            print(line.strip())
pathlib.Path(dest).write_text('\n'.join(texts))
