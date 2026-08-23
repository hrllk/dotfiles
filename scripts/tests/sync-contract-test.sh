#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$REPO_ROOT/ai/.hermes/scripts/sync-secrets"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sync-contract-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

failures=0
fail() { printf 'FAIL: %s\n' "$*" >&2; failures=$((failures + 1)); }

missing_key_dir="$TEST_ROOT/private-missing"
set +e
DOTFILES_KEY_DIR="$missing_key_dir" HERMES_LAUNCHD_ENV="$TEST_ROOT/runtime.env" \
  bash "$SCRIPT" >"$TEST_ROOT/missing.stdout" 2>"$TEST_ROOT/missing.stderr"
missing_code=$?
set -e
if (( missing_code != 1 )); then fail "missing input returned $missing_code, expected 1"; fi
if grep -Fq "$missing_key_dir" "$TEST_ROOT/missing.stderr"; then fail 'missing input leaked full secret path'; fi
if [[ -s "$TEST_ROOT/missing.stdout" ]]; then fail 'missing input wrote stdout'; fi

mkdir -p "$TEST_ROOT/keys/personal/discord"
printf 'redacted-test-value\n' > "$TEST_ROOT/keys/personal/discord/discord-user-id-alzar"
printf 'redacted-test-token\n' > "$TEST_ROOT/keys/personal/discord/discord-bot-token-default"
DOTFILES_KEY_DIR="$TEST_ROOT/keys" HERMES_LAUNCHD_ENV="$TEST_ROOT/runtime.env" \
  bash "$SCRIPT" >"$TEST_ROOT/success.stdout" 2>"$TEST_ROOT/success.stderr"
if grep -Fq "$TEST_ROOT" "$TEST_ROOT/success.stdout" "$TEST_ROOT/success.stderr"; then fail 'success output leaked test path'; fi
if grep -Fq 'redacted-test-' "$TEST_ROOT/success.stdout" "$TEST_ROOT/success.stderr"; then fail 'success output leaked secret value'; fi
if [[ ! -f "$TEST_ROOT/runtime.env" ]]; then fail 'runtime env was not created'; fi

if (( failures > 0 )); then
  printf 'SYNC_CONTRACT: FAIL (%s failures)\n' "$failures" >&2
  exit 1
fi
printf 'SYNC_CONTRACT: PASS\n'
