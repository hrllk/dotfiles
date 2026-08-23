#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-rerun-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"

failures=0
fail() { printf 'FAIL: %s\n' "$*" >&2; failures=$((failures + 1)); }

set +e
env HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
  DOTFILES_DIR="$REPO_ROOT" BACKUP_ROOT="$TEST_ROOT/backup" \
  BACKUP_TIMESTAMP=20260823-201500 \
  bash "$REPO_ROOT/scripts/bootstrap.sh" --dry-run --shell-only >"$TEST_ROOT/valid.output" 2>&1
valid_code=$?
set -e
if (( valid_code != 0 )); then fail "valid deterministic dry-run returned $valid_code"; fi
if [[ "$(grep -c 'timestamp: 20260823-201500' "$TEST_ROOT/valid.output")" != 1 ]]; then
  fail 'deterministic timestamp was not reported exactly once'
fi
if [[ -e "$TEST_ROOT/backup" ]]; then fail 'dry-run created backup root'; fi

set +e
env HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
  DOTFILES_DIR="$REPO_ROOT" BACKUP_ROOT="$TEST_ROOT/backup" \
  BACKUP_TIMESTAMP=bad \
  bash "$REPO_ROOT/scripts/bootstrap.sh" --dry-run --shell-only >"$TEST_ROOT/invalid.output" 2>&1
invalid_code=$?
set -e
if (( invalid_code != 2 )); then fail "invalid timestamp returned $invalid_code, expected 2"; fi

if (( failures > 0 )); then
  printf 'BOOTSTRAP_RERUN: FAIL (%s failures)\n' "$failures" >&2
  exit 1
fi
printf 'BOOTSTRAP_RERUN: PASS\n'
