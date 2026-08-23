#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
PLAN_ROOT="${GSTACK_PLAN_ROOT:-$HOME/.gstack/plans}"
BASELINE_FILE="$PLAN_ROOT/dotfiles-refactoring-baseline.md"
PATH_BASELINE_FILE="$PLAN_ROOT/dotfiles-path-baseline.md"

if [[ -f "$BASELINE_FILE" && -f "$PATH_BASELINE_FILE" && "${BASELINE_REFRESH:-0}" != 1 ]]; then
  printf 'BASELINE_SMOKE: EXISTING_BASELINE_PRESERVED\n'
  printf 'BASELINE_FILE: %s\n' "$BASELINE_FILE"
  printf 'PATH_BASELINE_FILE: %s\n' "$PATH_BASELINE_FILE"
  exit 0
fi

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-baseline.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/cache" "$TEST_ROOT/home/dotfiles"
ln -s "$REPO_ROOT" "$TEST_ROOT/home/dotfiles/repository"
ln -s "$REPO_ROOT/zsh/.zshrc" "$TEST_ROOT/home/.zshrc"

run_capture() {
  local output_file="$1"
  shift
  set +e
  "$@" >"$output_file" 2>&1
  local status=$?
  set -e
  printf '%s' "$status"
}

zsh_syntax=PASS
bash_syntax=PASS
zsh -n "$REPO_ROOT/zsh/.zshrc" "$REPO_ROOT/zsh/env.zsh" "$REPO_ROOT/zsh/path.zsh" || zsh_syntax=FAIL
bash -n "$REPO_ROOT/scripts/bootstrap.sh" "$REPO_ROOT/ai/.hermes/scripts/sync-secrets" || bash_syntax=FAIL

PATH_SNAPSHOT="$TEST_ROOT/path.snapshot"
zsh -fc 'typeset -p path; print -r -- "$PATH"' >"$PATH_SNAPSHOT" 2>/dev/null || true

STARTUP_OUTPUT="$TEST_ROOT/startup.output"
STARTUP_STATUS=$(run_capture "$STARTUP_OUTPUT" env \
  HOME="$TEST_ROOT/home" \
  ZDOTDIR="$TEST_ROOT/home" \
  XDG_CACHE_HOME="$TEST_ROOT/cache" \
  HISTFILE="$TEST_ROOT/home/.zsh_history" \
  zsh -lic 'typeset -p path; command -v git >/dev/null 2>&1; exit 0')

KNOWN_STDERR="$TEST_ROOT/known.stderr"
cp "$STARTUP_OUTPUT" "$KNOWN_STDERR"

COMMANDS=(zsh bash git grep rg ruby java node bun python3 nvim task-master)
{
  printf '%s\n' '# Baseline command resolution'
  for command_name in "${COMMANDS[@]}"; do
    resolved=$(command -v "$command_name" 2>/dev/null || true)
    if [[ -n "$resolved" ]]; then
      printf '| `%s` | `%s` |\n' "$command_name" "$resolved"
    else
      printf '| `%s` | ABSENT |\n' "$command_name"
    fi
  done
} >"$TEST_ROOT/commands.md"

mkdir -p "$PLAN_ROOT"
cat >"$BASELINE_FILE" <<EOF
# Dotfiles refactoring baseline

- Generated: baseline harness (timestamp intentionally omitted)
- Repository: $REPO_ROOT
- Secret values: not recorded
- Runtime file contents: not recorded

## Syntax

- zsh: $zsh_syntax
- bash: $bash_syntax

## Fresh startup

- exit: $STARTUP_STATUS
- known baseline output is stored as the current observation only
- startup output is not treated as a secret-bearing artifact

## Known startup stderr/output

~~~text
$(sed 's/`/\\`/g' "$KNOWN_STDERR")
~~~

## Command resolution

$(cat "$TEST_ROOT/commands.md")
EOF

cat >"$PATH_BASELINE_FILE" <<EOF
# Dotfiles PATH baseline

- Repository: $REPO_ROOT
- Secret values: not recorded
- Approval required before PATH resolution changes: yes

## Baseline PATH and command resolution

~~~text
$(sed 's/`/\\`/g' "$PATH_SNAPSHOT")
~~~

## Known startup stderr

See dotfiles-refactoring-baseline.md for the captured baseline observation.

## Approved resolution changes

| before | after | reason | task | approver | approved_at |
|---|---|---|---|---|---|
EOF

printf 'BASELINE_SMOKE: PASS\n'
printf 'REPO_ROOT: %s\n' "$REPO_ROOT"
printf 'BASELINE_FILE: %s\n' "$BASELINE_FILE"
printf 'PATH_BASELINE_FILE: %s\n' "$PATH_BASELINE_FILE"
printf 'STARTUP_STATUS: %s\n' "$STARTUP_STATUS"
printf 'ZSH_SYNTAX: %s\n' "$zsh_syntax"
printf 'BASH_SYNTAX: %s\n' "$bash_syntax"
