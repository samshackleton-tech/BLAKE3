#!/usr/bin/env python3
"""Serialized AFK queue. This orchestrates existing Cargo/bench-hashes tools;
it implements no timing loop or statistical rule. See AFK-20261024-PLAN.md.
"""
import datetime
import fcntl
import json
import os
from pathlib import Path
import random
import re
import shutil
import subprocess
import sys

R = Path('/root/results/afk-20261024-direct-flow')
WT = Path('/root/BLAKE3-direct-flow-gpr')
BENCH = WT / 'bench-hashes'
LIB_HEAD = '0627c0c38309a9e68ecf51ca1764978a67c6cb3d'
BENCH_HEAD = '9a87ea3d69cc7c56c0c1b857ca0d4edc9525a4f1'
PATCH = f'patch."https://github.com/johnservil/BLAKE3".blake3-servil.path="{WT}"'
B3SUM = '/root/results/released-cli-v7/bin/b3sum-official-1.8.2-L0'
TARGET = Path('/root/BLAKE3-gpr-with-out/bench-contract-18de07c-backup/target')
POINTS = {
    'serial': ('0,2', 'blake3-servil-st', 'lent 64 B,lent 256 B,lent 1 KiB,lent batch 16,lent batch 64,lent batch 256'),
    'stream': ('0,2,4,6', 'blake3-servil-mt', 'continuous 64 B,continuous 256 B,continuous 1 KiB,continuous batch 64'),
}
PLANTED_CELL = 'blake3-servil-st|solo|LentMessages|64 B'
STATE = {'stages': [], 'controls_pass': None, 'complete': False}
STARTED = False
ENV = os.environ.copy()
ENV.pop('BLAKE3_DIAGNOSTIC_GPR', None)
ENV['CARGO_TARGET_DIR'] = str(TARGET)


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def save():
    tmp = R / 'state.json.tmp'
    tmp.write_text(json.dumps(STATE, indent=2) + '\n')
    tmp.replace(R / 'state.json')


def mark(message):
    line = f'{now()} {message}'
    print(line, flush=True)
    with (R / 'status.log').open('a') as out:
        out.write(line + '\n')


def run(args, name, cwd=BENCH, env=None, timeout=3600, accepted=(0,)):
    mark('begin ' + name)
    log = R / (name + '.log')
    log.parent.mkdir(parents=True, exist_ok=True)
    stage = {'name': name, 'args': [str(a) for a in args], 'start': now()}
    STATE['stages'].append(stage)
    save()
    with log.open('w') as out:
        try:
            done = subprocess.run([str(a) for a in args], cwd=cwd, env=ENV if env is None else env,
                                  stdout=out, stderr=subprocess.STDOUT, timeout=timeout)
            code = done.returncode
        except subprocess.TimeoutExpired:
            stage['exit'] = 'timeout-unresolved'
            stage['end'] = now()
            save()
            raise
    stage.update(exit=code, end=now())
    save()
    mark(f'end {name}: exit={code}')
    if code not in accepted:
        raise RuntimeError(f'{name} failed ({code}); see {log}')
    return code


def head(path):
    return subprocess.run(['git', '-C', str(path), 'rev-parse', 'HEAD'], check=True,
                          capture_output=True, text=True).stdout.strip()


def build_group(name, gpr=False, fill=False, plant=False):
    group = R / 'bin' / name
    group.mkdir(parents=True)
    flags = ['diag-direct-flow']
    if fill:
        flags.append('diag-direct-fill')
    if plant:
        flags.append('diag-direct-plant')
    env = ENV.copy()
    if gpr:
        env['BLAKE3_DIAGNOSTIC_GPR'] = '1'
    (group / 'manifest.json').write_text(json.dumps({
        'library': LIB_HEAD, 'bench': BENCH_HEAD, 'features': flags,
        'BLAKE3_DIAGNOSTIC_GPR': env.get('BLAKE3_DIAGNOSTIC_GPR'),
        'layouts': 16, 'seed_prefix': 'afk-' + name,
    }, indent=2) + '\n')
    for i in range(16):
        symbols = (R / 'symbols.txt').read_text().splitlines()
        random.Random(f'afk-{name}-{i}').shuffle(symbols)
        order = group / f'order-{i}.txt'
        order.write_text('\n'.join(symbols) + '\n')
        run(['cargo', '--config', PATCH, 'rustc', '-q', '--release', '--features', ','.join(flags),
             '--bin', 'bench-hashes', '--', '-Clink-arg=-fuse-ld=lld',
             f'-Clink-arg=-B{R / "lld"}', f'-Clink-arg=-Wl,--symbol-ordering-file={order}',
             '-Clink-arg=-Wl,--no-warn-symbol-ordering'], f'build/{name}-{i}', env=env, timeout=1200)
        shutil.copy2(TARGET / 'release/bench-hashes', group / f'bench-{i}')
    bins = [group / f'bench-{i}' for i in range(16)]
    for command, output in [('sha256sum', 'binaries.sha256'), (B3SUM, 'binaries.blake3')]:
        with (group / output).open('w') as out:
            subprocess.run([command, *map(str, bins)], check=True, stdout=out)
    mark('group ready: ' + name)
    return bins


def compare_groups(name, old, new, family):
    affinity, contenders, points = POINTS[family]
    dest = R / name / family
    dest.mkdir(parents=True)
    if family == 'stream':
        wrappers = []
        for side, bins in [('old', old), ('new', new)]:
            wrapped = []
            for i, exe in enumerate(bins):
                path = dest / f'{side}-{i}.sh'
                path.write_text(f'#!/bin/sh\nexec {exe} --threads 4 "$@"\n')
                path.chmod(0o755)
                wrapped.append(path)
            wrappers.append(wrapped)
        before, after = wrappers
    else:
        before, after = old, new
    code = run(['taskset', '-c', affinity, old[0], 'regress', '--contenders', contenders,
                '--points', points, '--pairs', '16', '--keep', dest / 'samples',
                *before, '--', *after], f'{name}/{family}/regress', cwd=dest,
               timeout=1800, accepted=(0, 1, 2))
    text = (dest / 'regress.log').read_text()
    slower = re.findall(r'^\s+SLOWER (.+?):', text, re.M)
    old_samples = sorted((dest / 'samples').glob('run-*-old.tsv'))
    new_samples = sorted((dest / 'samples').glob('run-*-new.tsv'))
    if len(old_samples) == len(new_samples) and len(old_samples) >= 3:
        run([old[0], 'compare', *old_samples, '--', *new_samples], f'{name}/{family}/compare', cwd=dest, timeout=120)
    outcome = {'exit': code, 'slower': slower,
               'old_samples': len(old_samples), 'new_samples': len(new_samples)}
    (dest / 'outcome.json').write_text(json.dumps(outcome, indent=2) + '\n')
    mark(f'{name}/{family}: {outcome}')
    return outcome


def main():
    global STARTED
    R.mkdir(parents=True, exist_ok=True)
    if (R / 'state.json').exists():
        raise RuntimeError('Results already exist; preserve them rather than restarting over them')
    lock = open('/root/bench-native-afk.lock', 'w')
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    running = subprocess.run(['ps', '-eo', 'comm='], check=True, capture_output=True, text=True).stdout.split()
    if any(c in ('cargo', 'rustc', 'perf', 'bpftrace') or c.startswith('bench-hashes') for c in running):
        raise RuntimeError('another native job is active')
    assert head(WT) == LIB_HEAD
    assert head(BENCH) == 'd87f18ad70b55f5d53fe553bb4ff93a2139d642d'
    shutil.move(str(BENCH), str(R / 'previous-benchmark-checkout'))
    subprocess.run(['git', 'clone', '-q', '-b', 'experiment/sam-direct-flow-calibration',
                    '/root/bench-direct-calibration.bundle', str(BENCH)], check=True)
    subprocess.run(['git', '-C', str(BENCH), 'remote', 'set-url', 'origin',
                    'https://github.com/samshackleton-tech/bench-hashes'], check=True)
    assert head(BENCH) == BENCH_HEAD
    STATE.update(start=now(), library=LIB_HEAD, bench=BENCH_HEAD, pid=os.getpid())
    STARTED = True
    save()
    (R / 'pid').write_text(str(os.getpid()) + '\n')
    run(['cargo', '--config', PATCH, 'update', '-q', '-p', 'blake3-servil'], 'setup/update', timeout=180)
    for label, features in [('plain', 'diag-direct-flow'), ('plant', 'diag-direct-plant'),
                            ('fill', 'diag-direct-fill')]:
        run(['cargo', 'nextest', 'run', '--config', PATCH, '--release', '--features', features],
            f'tests/{label}', timeout=900)
    run(['cargo', '--config', PATCH, 'build', '-q', '--release', '--features', 'diag-direct-flow'],
        'setup/reference-build', timeout=900)
    nm = subprocess.run(['nm', str(TARGET / 'release/bench-hashes')], check=True,
                        capture_output=True, text=True).stdout.splitlines()
    symbols = sorted({f[2] for line in nm if len(f := line.split()) == 3 and f[1] in 'tT'})
    (R / 'symbols.txt').write_text('\n'.join(symbols) + '\n')
    (R / 'lld').mkdir()
    lld = shutil.which('ld.lld')
    if lld is None:
        lld = str(sorted(Path('/usr/bin').glob('ld.lld-*'))[-1])
    (R / 'lld/ld.lld').symlink_to(lld)

    a = build_group('simd-a')
    b = build_group('simd-b')
    aa = [compare_groups('aa', a, b, f) for f in POINTS]
    aa_pass = all(o['exit'] == 0 and not o['slower'] for o in aa)
    planted = build_group('plant')
    positive = compare_groups('plant', a, planted, 'serial')
    plant_pass = positive['exit'] == 1 and positive['slower'] == [PLANTED_CELL]
    STATE['controls_pass'] = aa_pass and plant_pass
    STATE['aa_pass'], STATE['plant_pass'] = aa_pass, plant_pass
    save()
    if STATE['controls_pass']:
        gpr = build_group('gpr-words', gpr=True)
        for family in POINTS:
            compare_groups('gpr-words', a, gpr, family)
        fill_simd = build_group('simd-fill', fill=True)
        fill_gpr = build_group('gpr-fill', gpr=True, fill=True)
        for family in POINTS:
            compare_groups('gpr-fill', fill_simd, fill_gpr, family)
    else:
        mark('BLOCKED: direct-flow implementation comparisons await control diagnosis')

    # Independent diagnostic: after-gap cells are untouched by direct-flow.
    for i in range(3):
        run(['python3', '/root/offset-core-103adbf.py', '--axis', 'core', '--exe', a[i],
             '--keep', R / 'core-axis' / f'layout-{i}'], f'core-axis/layout-{i}',
            cwd=R, timeout=900, accepted=(0, 1, 2, 3))
    STATE.update(complete=True, end=now())
    save()
    mark('AFK queue complete; all results retained')


if __name__ == '__main__':
    try:
        main()
    except BaseException as error:
        if STARTED:
            STATE.update(error=repr(error), failed_at=now())
            save()
            mark('STOPPED: ' + repr(error))
        raise
