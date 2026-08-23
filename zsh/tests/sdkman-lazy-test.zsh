#!/usr/bin/env zsh
set -u

REPO_ROOT="${${(%):-%x}:A:h:h:h}"
LOADER="$REPO_ROOT/zsh/integrations/lazy/sdkman.zsh"
TEST_ROOT="${TMPDIR:-/tmp}/sdkman-lazy-test.$$"
mkdir -p "$TEST_ROOT/uninstalled" "$TEST_ROOT/installed/bin" "$TEST_ROOT/no-java/bin"
trap 'command /bin/rm -rf "$TEST_ROOT"' EXIT

failures=0
fail() { print -u2 -- "FAIL: $*"; failures=$((failures + 1)); }

# Uninstalled fixture.
set +e
HOME="$TEST_ROOT/uninstalled" zsh -fc 'source "$1"; sdk test' zsh "$LOADER" \
  >"$TEST_ROOT/uninstalled.stdout" 2>"$TEST_ROOT/uninstalled.stderr"
uninstalled_code=$?
set -e
if (( uninstalled_code != 127 )); then fail "uninstalled sdk exit was $uninstalled_code, expected 127"; fi
if [[ -n "$(cat "$TEST_ROOT/uninstalled.stdout")" ]]; then fail "uninstalled sdk stdout was not empty"; fi
if [[ "$(wc -l < "$TEST_ROOT/uninstalled.stderr" | tr -d ' ')" != 1 ]]; then fail "uninstalled sdk stderr was not exactly one line"; fi

# Installed fixture: init must happen exactly once.
mkdir -p "$TEST_ROOT/installed/.sdkman/bin"
print -r -- 0 > "$TEST_ROOT/installed/marker"
cat > "$TEST_ROOT/installed/.sdkman/bin/sdkman-init.sh" <<'EOF'
marker="${SDKMAN_MARKER:?}"
count=$(/bin/cat "$marker")
/usr/bin/printf '%s\n' "$((count + 1))" > "$marker"
sdk() { print -r -- "sdk:$*"; return 0; }
EOF
installed_output=$(HOME="$TEST_ROOT/installed" SDKMAN_MARKER="$TEST_ROOT/installed/marker" \
  zsh -fc 'source "$1"; sdk first; sdk second' zsh "$LOADER" 2>"$TEST_ROOT/installed.stderr")
if [[ "$(cat "$TEST_ROOT/installed/marker")" != 1 ]]; then fail "SDKMAN marker was not 0->1->1"; fi
if [[ "$installed_output" != $'sdk:first\nsdk:second' ]]; then fail "installed sdk output mismatch: $installed_output"; fi

# Java candidate absent: loader must not invent JAVA_HOME or java command.
mkdir -p "$TEST_ROOT/no-java/.sdkman/bin" "$TEST_ROOT/no-java/empty-path"
print -r -- 0 > "$TEST_ROOT/no-java/marker"
cat > "$TEST_ROOT/no-java/.sdkman/bin/sdkman-init.sh" <<'EOF'
marker="${SDKMAN_MARKER:?}"
count=$(/bin/cat "$marker")
/usr/bin/printf '%s\n' "$((count + 1))" > "$marker"
sdk() { return 0; }
EOF
set +e
java_output=$(HOME="$TEST_ROOT/no-java" PATH="/bin" SDKMAN_MARKER="$TEST_ROOT/no-java/marker" \
  zsh -fc 'unset JAVA_HOME; source "$1"; sdk java; command -v java >/dev/null 2>&1' zsh "$LOADER" 2>"$TEST_ROOT/no-java.stderr")
java_code=$?
set -e
if (( java_code != 1 )); then fail "no-java command resolution exit was $java_code, expected 1"; fi
if [[ -n "$java_output" ]]; then fail "no-java fixture produced unexpected output"; fi
if [[ "$(cat "$TEST_ROOT/no-java/marker")" != 1 ]]; then fail "no-java marker was not 1"; fi

if (( failures > 0 )); then
  print -u2 -- "SDKMAN_LAZY: FAIL ($failures failures)"
  exit 1
fi
print -- "SDKMAN_LAZY: PASS"
