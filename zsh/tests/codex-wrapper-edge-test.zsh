#!/usr/bin/env zsh
set -u

ROOT="${0:A:h:h}"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_HOME/.codex" "$TMP_HOME/bin"
cat > "$TMP_HOME/bin/codex" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${CODEX_TEST_ARGS_FILE}"
exit 0
EOF
chmod 755 "$TMP_HOME/bin/codex"
export HOME="$TMP_HOME" CODEX_HOME="$TMP_HOME/.codex" PATH="$TMP_HOME/bin:$PATH"

source "$ROOT/aliases/codex.zsh"

# Explicit profile bypasses local profile preconditions and preserves argv.
export CODEX_TEST_ARGS_FILE="$TMP_HOME/explicit.args"
codex --profile other exec prompt
expected=(--profile other exec prompt)
actual=("${(@f)$(<"$CODEX_TEST_ARGS_FILE")}")
[[ "${actual[*]}" == "${expected[*]}" ]] || exit 1

# Compact profile forms are also passed through unchanged.
export CODEX_TEST_ARGS_FILE="$TMP_HOME/compact.args"
codex -pcompact exec prompt
expected=(-pcompact exec prompt)
actual=("${(@f)$(<"$CODEX_TEST_ARGS_FILE")}")
[[ "${actual[*]}" == "${expected[*]}" ]] || exit 1
export CODEX_TEST_ARGS_FILE="$TMP_HOME/equal.args"
codex --profile=other exec prompt
expected=(--profile=other exec prompt)
actual=("${(@f)$(<"$CODEX_TEST_ARGS_FILE")}")
[[ "${actual[*]}" == "${expected[*]}" ]] || exit 1

# Missing local profile fails closed and must not invoke Codex.
export CODEX_TEST_ARGS_FILE="$TMP_HOME/missing.args"
set +e
codex exec prompt >/dev/null 2>"$TMP_HOME/missing.err"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || exit 1
[[ ! -e "$CODEX_TEST_ARGS_FILE" ]] || exit 1
[[ "$(<"$TMP_HOME/missing.err")" == *"local profile is missing"* ]] || exit 1

# Unsafe permissions fail closed.
cat > "$CODEX_HOME/local.config.toml" <<'EOF'
[projects."/tmp/example"]
trust_level = "trusted"
EOF
chmod 666 "$CODEX_HOME/local.config.toml"
export CODEX_TEST_ARGS_FILE="$TMP_HOME/unsafe.args"
set +e
codex exec prompt >/dev/null 2>"$TMP_HOME/unsafe.err"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || exit 1
[[ ! -e "$CODEX_TEST_ARGS_FILE" ]] || exit 1
[[ "$(<"$TMP_HOME/unsafe.err")" == *"group/world-writable"* ]] || exit 1

# -- stops profile parsing, while wrapper still injects local before argv.
chmod 600 "$CODEX_HOME/local.config.toml"
export CODEX_TEST_ARGS_FILE="$TMP_HOME/dash.args"
codex exec -- "-p" prompt
expected=(-p local exec -- -p prompt)
actual=("${(@f)$(<"$CODEX_TEST_ARGS_FILE")}")
[[ "${actual[*]}" == "${expected[*]}" ]] || exit 1

print "PASS: explicit profile, fail-closed checks, and -- boundary"
