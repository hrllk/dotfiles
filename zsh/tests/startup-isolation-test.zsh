#!/usr/bin/env zsh
set -u

REPO_ROOT="${${(%):-%x}:A:h:h:h}"
TEST_ROOT="${TMPDIR:-/tmp}/startup-isolation-test.$$"
mkdir -p "$TEST_ROOT/home/.hermes/scripts" "$TEST_ROOT/cache"
ln -s "$REPO_ROOT" "$TEST_ROOT/home/dotfiles"
ln -s "$REPO_ROOT/zsh/.zshrc" "$TEST_ROOT/home/.zshrc"
print -r -- 0 > "$TEST_ROOT/sync.count"
cat > "$TEST_ROOT/home/.hermes/scripts/sync-secrets" <<'EOF'
#!/usr/bin/env bash
count_file="${SYNC_SENTINEL:?}"
count=$(cat "$count_file")
printf '%s\n' "$((count + 1))" > "$count_file"
exit 0
EOF
chmod +x "$TEST_ROOT/home/.hermes/scripts/sync-secrets"
trap 'command /bin/rm -rf "$TEST_ROOT"' EXIT

output_file="$TEST_ROOT/startup.output"
err_file="$TEST_ROOT/startup.stderr"
set +e
env HOME="$TEST_ROOT/home" ZDOTDIR="$TEST_ROOT/home" \
  XDG_CACHE_HOME="$TEST_ROOT/cache" HISTFILE="$TEST_ROOT/home/.zsh_history" \
  SYNC_SENTINEL="$TEST_ROOT/sync.count" \
  zsh -lic 'typeset -f sdk >/dev/null 2>&1; (( $+functions[reload_zshrc] )) && exit 7; exit 0' \
  >"$output_file" 2>"$err_file"
exit_code=$?
set -e

failures=0
if (( exit_code != 0 )); then
  print -u2 -- "FAIL: startup exit was $exit_code"
  failures=$((failures + 1))
fi
if [[ "$(cat "$TEST_ROOT/sync.count")" != 0 ]]; then
  print -u2 -- "FAIL: startup invoked sync-secrets"
  failures=$((failures + 1))
fi
if grep -Fq '/Users/hrk/.sdkman/bin/sdkman-init.sh' "$REPO_ROOT/zsh/.zshrc"; then
  print -u2 -- "FAIL: .zshrc contains eager SDKMAN init"
  failures=$((failures + 1))
fi
if grep -Fq "$TEST_ROOT" "$err_file"; then
  print -u2 -- "FAIL: startup leaked a full secret path"
  failures=$((failures + 1))
fi

if (( failures > 0 )); then
  print -u2 -- "STARTUP_ISOLATION: FAIL ($failures failures)"
  cat "$err_file" >&2
  exit 1
fi

print -- "STARTUP_ISOLATION: PASS"
