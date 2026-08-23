#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
HELPER="$REPO_ROOT/ai/.claude/scripts/link-claude-home"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/claude-backup-contract.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/home/.claude" "$TEST_ROOT/backup" "$TEST_ROOT/backup/.claude.bak.20260823-201500"

set +e
HOME="$TEST_ROOT/home" CLAUDE_HOME="$TEST_ROOT/home/.claude" \
  DOTFILES_DIR="$REPO_ROOT" BACKUP_ROOT="$TEST_ROOT/backup" \
  BACKUP_TIMESTAMP=20260823-201500 \
  "$HELPER" --yes >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
code=$?
set -e

if (( code != 0 )); then
  printf 'CLAUDE_BACKUP_CONTRACT: FAIL (helper returned %s)\n' "$code" >&2
  cat "$TEST_ROOT/error" >&2
  exit 1
fi

if [[ ! -d "$TEST_ROOT/backup/.claude.bak.20260823-201500.1" ]]; then
  printf 'CLAUDE_BACKUP_CONTRACT: FAIL (shared timestamp not used)\n' >&2
  find "$TEST_ROOT" -maxdepth 4 -print >&2
  exit 1
fi

printf 'CLAUDE_BACKUP_CONTRACT: PASS\n'
