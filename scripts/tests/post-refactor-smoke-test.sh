#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

run() {
  printf '\n== %s ==\n' "$1"
  shift
  "$@"
}

run path-ownership zsh "$REPO_ROOT/zsh/tests/path-ownership-test.zsh"
run startup-isolation zsh "$REPO_ROOT/zsh/tests/startup-isolation-test.zsh"
run sdkman-lazy zsh "$REPO_ROOT/zsh/tests/sdkman-lazy-test.zsh"
run bootstrap-matrix bash "$REPO_ROOT/scripts/tests/bootstrap-matrix-test.sh"
run bootstrap-rerun bash "$REPO_ROOT/scripts/tests/bootstrap-rerun-test.sh"
run claude-backup-contract bash "$REPO_ROOT/scripts/tests/claude-backup-contract-test.sh"
run sync-contract bash "$REPO_ROOT/scripts/tests/sync-contract-test.sh"
run tmux-unread bash "$REPO_ROOT/scripts/tests/tmux-unread-test.sh"

printf '\nPOST_REFACTOR_SMOKE: PASS\n'
