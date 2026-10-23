#!/usr/bin/env python3
"""Exercise the unchanged public reach.py on two small native Rust crates.
No optimization sources or private performance results are involved.
"""
from pathlib import Path
import json, os, shutil, subprocess, sys

source = Path(sys.argv[1])
report = Path(sys.argv[2]).resolve()
report.mkdir(parents=True, exist_ok=True)
replace = shutil.which('replace')
assert replace
cases = [
    ('constant-file', {
        'src/constants.rs': 'pub const ANSWER: u32 = 7;\n',
        'src/lib.rs': 'mod constants;\npub fn answer() -> u32 {\n    constants::ANSWER\n}\n#[test]\nfn answer_is_seven() {\n    assert_eq!(answer(), 7);\n}\n',
    }, 'src/constants.rs', 'pub const ANSWER: u32 = 7;', 'pub const ANSWER: u32 = 9;'),
    ('transitive-constant', {
        'src/lib.rs': 'const A: u16 = 3;\nconst B: u16 = A;\npub fn direct() -> u8 {\n    A as u8\n}\npub fn indirect() -> u16 {\n    B\n}\n#[test]\nfn direct_low_byte() {\n    assert_eq!(direct(), 3);\n}\n#[test]\nfn indirect_full_width() {\n    assert_eq!(indirect(), 3);\n}\n',
    }, 'src/lib.rs', 'const A: u16 = 3;', 'const A: u16 = 259;'),
]
records = []
for name, files, changed, old, new in cases:
    root = report / name
    root.mkdir(exist_ok=False)
    (root / 'src').mkdir()
    (root / 'tools/tests').mkdir(parents=True)
    shutil.copyfile(source, root / 'tools/tests/reach.py')
    (root / '.gitignore').write_text('/target/\n/tmp/\n')
    (root / 'Cargo.toml').write_text(f'[package]\nname = "reach-fixture-{name}"\nversion = "0.1.0"\nedition = "2021"\n')
    for path, text in files.items(): (root / path).write_text(text)
    # Track the generated lock before mapping, so untracked Cargo.lock
    # cannot force every test and mask the selector behavior being tested.
    subprocess.run(['cargo', 'generate-lockfile'], cwd=root, check=True)
    subprocess.run(['git', 'init', '-q'], cwd=root, check=True)
    subprocess.run(['git', 'add', '-A'], cwd=root, check=True)
    subprocess.run(['git', '-c', 'core.hooksPath=/dev/null', '-c', 'user.name=Sam Shackleton', '-c', 'user.email=samshackleton-tech@users.noreply.github.com', 'commit', '-qm', 'Reference fixture'], cwd=root, check=True)
    def run(label, args):
        with (report / f'{name}-{label}.log').open('w') as log:
            result = subprocess.run(args, cwd=root, stdout=log, stderr=subprocess.STDOUT)
        print(name, label, 'exit', result.returncode, flush=True)
        return result.returncode
    assert run('map', ['python3', 'tools/tests/reach.py', 'map']) == 0
    with (report / f'{name}-change.diff').open('w') as log:
        subprocess.run([replace, str(root / changed), old, new], check=True, stdout=log, stderr=subprocess.STDOUT)
    dry = run('dry', ['python3', 'tools/tests/reach.py', 'check', '--dry-run'])
    selected = run('selected', ['python3', 'tools/tests/reach.py', 'check'])
    full = run('full', ['cargo', 'nextest', 'run', '--release', '--lib', '--tests'])
    record = {'case': name, 'dry_exit': dry, 'selected_exit': selected, 'full_exit': full}
    records.append(record)
    (report / 'outcomes.json').write_text(json.dumps(records, indent=2) + '\n')
    assert dry == 0 and selected == 0 and full == 100, record
print('Both controls reproduced: selected check succeeds, full suite detects the change.', flush=True)
