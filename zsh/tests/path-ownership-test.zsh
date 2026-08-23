#!/usr/bin/env zsh
set -u

REPO_ROOT="${${(%):-%x}:A:h:h:h}"
ENV_FILE="$REPO_ROOT/zsh/env.zsh"
PATH_FILE="$REPO_ROOT/zsh/path.zsh"
failures=0

fail() {
  print -u2 -- "FAIL: $*"
  failures=$((failures + 1))
}

assert_not_contains() {
  local pattern="$1"
  local file="$2"
  if grep -Eq "$pattern" "$file"; then
    fail "$file contains forbidden PATH mutation pattern: $pattern"
  fi
}

assert_not_contains '(^|[^A-Za-z_])(PATH|path|path_add)[[:space:]]*=' "$ENV_FILE"
assert_not_contains 'rbenv init' "$ENV_FILE"
assert_not_contains 'source[[:space:]].*_bun' "$ENV_FILE"

fixture_root="${TMPDIR:-/tmp}/path-ownership-test.$$"
mkdir -p "$fixture_root"
trap 'command /bin/rm -rf "$fixture_root"' EXIT

before_path=("$fixture_root/inherited-a" "$fixture_root/inherited-b")
path=("${before_path[@]}")
PATH="${(j.:.)path}"
source "$ENV_FILE"
after_path=("${path[@]}")
after_path_value="$PATH"
expected_path_value="${(j.:.)before_path}"

if [[ "${(j.|.)after_path[*]}" != "${(j.|.)before_path[*]}" ]]; then
  fail "source env.zsh changed path array"
fi
if [[ "$after_path_value" != "$expected_path_value" ]]; then
  fail "source env.zsh changed PATH"
fi

if (( failures > 0 )); then
  print -u2 -- "PATH_OWNERSHIP: FAIL ($failures failures)"
  exit 1
fi

print -- "PATH_OWNERSHIP: PASS"
