#!/usr/bin/env python3
"""Native coverage control: a const fn has runtime and compile-time consumers.
Run serially on the EPYC, not on the possibly shared local i7.
"""
from pathlib import Path
import json, shutil, subprocess, sys

source = Path(sys.argv[1]).resolve()
report = Path(sys.argv[2]).resolve()
mode = sys.argv[3]
headers = {'plain': 'const fn base()', 'extern-c': 'const extern "C" fn base()', 'split': 'const\nfn base()'}
assert mode in headers, mode
report.mkdir(parents=True, exist_ok=False)
root = report / 'fixture'
(root / 'src').mkdir(parents=True)
(root / 'tools/tests').mkdir(parents=True)
shutil.copyfile(source, root / 'tools/tests/reach.py')
(root / '.gitignore').write_text('/target/\n/tmp/\n')
(root / 'Cargo.toml').write_text('[package]\nname = "reach-const-fn-fixture"\nversion = "0.1.0"\nedition = "2021"\n\n[features]\n# Empty compatibility features match the selector\'s suite options.\nserde = []\nzeroize = []\n')
(root / 'src/lib.rs').write_text('''#[inline(never)]
const fn base() -> u16 {
    3
}
const B: u16 = base();
pub fn direct() -> u8 {
    base() as u8
}
pub fn indirect() -> u16 {
    B
}
#[test]
fn direct_low_byte() {
    assert_eq!(direct(), 3);
}
#[test]
fn indirect_full_width() {
    assert_eq!(indirect(), 3);
}
'''.replace('const fn base()', headers[mode]))
subprocess.run(['cargo', 'generate-lockfile'], cwd=root, check=True)
subprocess.run(['git', 'init', '-q'], cwd=root, check=True)
subprocess.run(['git', 'add', '-A'], cwd=root, check=True)
subprocess.run(['git', '-c', 'core.hooksPath=/dev/null', '-c', 'user.name=Sam Shackleton', '-c', 'user.email=samshackleton-tech@users.noreply.github.com', 'commit', '-qm', 'Native const-fn control'], cwd=root, check=True)
def run(name, command):
    with (report / f'{name}.log').open('w') as log:
        result = subprocess.run(command, cwd=root, stdout=log, stderr=subprocess.STDOUT)
    print(name, 'exit', result.returncode, flush=True)
    return result.returncode
assert run('map', ['python3', 'tools/tests/reach.py', 'map']) == 0
with (report / 'change.diff').open('w') as log:
    subprocess.run(['replace', str(root / 'src/lib.rs'), '    3\n}', '    259\n}'], check=True, stdout=log, stderr=subprocess.STDOUT)
dry = run('dry', ['python3', 'tools/tests/reach.py', 'check', '--dry-run'])
selected = run('selected', ['python3', 'tools/tests/reach.py', 'check'])
full = run('full', ['cargo', 'nextest', 'run', '--release', '--lib', '--tests', '--features', 'serde,zeroize'])
outcome = dict(mode=mode, dry_exit=dry, selected_exit=selected, full_exit=full)
(report / 'outcome.json').write_text(json.dumps(outcome, indent=2) + '\n')
assert full == 100, outcome
print('FALSE GREEN' if selected == 0 else 'Selector did not return green; inspect its actual log.', flush=True)
