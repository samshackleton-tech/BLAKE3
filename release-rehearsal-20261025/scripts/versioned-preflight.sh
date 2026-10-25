#!/bin/bash
# No upload: cargo publish is used only with --dry-run.
set -euo pipefail
. /root/.cargo/env
r=/root/results/release-version-rehearsal-20261025
exec > "$r/versioned-runner.log" 2>&1
trap 'echo "versioned preflight exit=$? $(date -Is)" >> "$r/status.log"' EXIT
exec 9>/root/bench-native-afk.lock
flock -n 9 || exit 3
cd "$r/checkout"
python3 - "$r" <<'PY'
import importlib.util,json,pathlib,subprocess,sys
r=pathlib.Path(sys.argv[1]);spec=importlib.util.spec_from_file_location('release_check',r/'updated-release-check.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
previous=m.previous_release(head)
assert previous=='v0.3.0+2e4fa821f9db07b945dbb2b0d02eb76cb19617b5',previous
(r/'fixed-selector.json').write_text(json.dumps({'rehearsal_only':True,'candidate':head,'previous':previous,'checker_source':'998ce7ba8a978dba0c505b6ebbc0c070cd2b5b97'},indent=2)+'\n')
print('fixed selector:',previous)
PY
(CARGO_TARGET_DIR=/root/target-versioned-package cargo publish --dry-run > "$r/library-dry-run.log" 2>&1) & library=$!
(CARGO_TARGET_DIR=/root/target-versioned-cli cargo publish --dry-run --manifest-path b3sum/Cargo.toml > "$r/cli-dry-run.log" 2>&1) & cli=$!
(CARGO_TARGET_DIR=/root/target-versioned-capi cargo nextest run --release --manifest-path capi/Cargo.toml > "$r/versioned-capi.log" 2>&1) & capi=$!
set +e
wait "$library"; a=$?
wait "$cli"; b=$?
wait "$capi"; c=$?
set -e
printf 'library dry-run=%s cli dry-run=%s versioned capi=%s\n' "$a" "$b" "$c" >> "$r/status.log"
python3 - "$r" "$a" "$b" "$c" <<'PY'
import json,pathlib,sys
pathlib.Path(sys.argv[1],'dry-run-results.json').write_text(json.dumps({'rehearsal_only':True,'library_dry_run_exit':int(sys.argv[2]),'cli_dry_run_exit':int(sys.argv[3]),'versioned_capi_exit':int(sys.argv[4]),'uploaded':False},indent=2)+'\n')
PY
git status --porcelain > "$r/status-after-checks.txt"
git -C /root/BLAKE3-private-symbols-review show-ref --tags > "$r/production-tags-after-checks.txt"
cmp "$r/production-tags-before.txt" "$r/production-tags-after-checks.txt"
echo "versioned checks finished; individual outcomes recorded; no publication $(date -Is)" >> "$r/status.log"
