#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-matrix-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home"

cat > "$TEST_ROOT/bin/git" <<'EOF'
#!/usr/bin/env bash
printf 'git-called\n' >> "${CALL_LOG:?}"
exit 91
EOF
chmod +x "$TEST_ROOT/bin/git"

failures=0
fail() { printf 'FAIL: %s\n' "$*" >&2; failures=$((failures + 1)); }

run_invalid() {
  local label="$1"
  shift
  local output_file="$TEST_ROOT/$label.output"
  set +e
  env HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
    DOTFILES_DIR="$REPO_ROOT" BACKUP_ROOT="$TEST_ROOT/backup" \
    CALL_LOG="$TEST_ROOT/calls.log" \
    bash "$REPO_ROOT/scripts/bootstrap.sh" "$@" >"$output_file" 2>&1
  local code=$?
  set -e
  if (( code != 2 )); then
    fail "$label returned $code, expected 2"
  fi
  if grep -q '^git-called$' "$TEST_ROOT/calls.log" 2>/dev/null; then
    fail "$label called a stage before validation"
    : > "$TEST_ROOT/calls.log"
  fi
}

: > "$TEST_ROOT/calls.log"
run_invalid dry-shell-ai --dry-run --shell-only --ai
run_invalid dry-shell-sync --dry-run --shell-only --sync-secrets
run_invalid shell-ai-sync --shell-only --ai --sync-secrets
run_invalid all-invalid --dry-run --shell-only --ai --sync-secrets

run_dry_run() {
  local label="$1"
  shift
  local dry_home="$TEST_ROOT/$label-home"
  mkdir -p "$dry_home"
  set +e
  env HOME="$dry_home" PATH="$TEST_ROOT/bin:/usr/bin:/bin" \
    DOTFILES_DIR="$REPO_ROOT" BACKUP_ROOT="$TEST_ROOT/$label-backup" \
    BACKUP_TIMESTAMP=20260823-201500 \
    bash "$REPO_ROOT/scripts/bootstrap.sh" --dry-run "$@" >"$TEST_ROOT/$label.output" 2>&1
  local code=$?
  set -e
  if (( code != 0 )); then fail "$label returned $code, expected 0"; fi
  if [[ -e "$dry_home/.zshrc" || -e "$dry_home/.hermes" || -e "$dry_home/.claude" ]]; then
    fail "$label created a target during dry-run"
  fi
  if [[ -e "$TEST_ROOT/$label-backup" ]]; then
    fail "$label created BACKUP_ROOT during dry-run"
  fi
}

run_dry_run shell --shell-only
run_dry_run ai --ai
run_dry_run ai-sync --ai --sync-secrets

if (( failures > 0 )); then
  printf 'BOOTSTRAP_MATRIX: FAIL (%s failures)\n' "$failures" >&2
  exit 1
fi
printf 'BOOTSTRAP_MATRIX: PASS\n'
