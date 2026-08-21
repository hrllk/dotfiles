#!/usr/bin/env zsh
set -u

ROOT="${0:A:h:h}"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

mkdir -p "$TMP_HOME/.codex" "$TMP_HOME/bin"
cat > "$TMP_HOME/.codex/local.config.toml" <<'EOF'
[projects."/tmp/example"]
trust_level = "trusted"
EOF
chmod 600 "$TMP_HOME/.codex/local.config.toml"

cat > "$TMP_HOME/bin/codex" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${CODEX_TEST_ARGS_FILE}"
exit 37
EOF
chmod 755 "$TMP_HOME/bin/codex"

export HOME="$TMP_HOME"
export CODEX_HOME="$TMP_HOME/.codex"
export CODEX_TEST_ARGS_FILE="$TMP_HOME/args"
export PATH="$TMP_HOME/bin:$PATH"

source "$ROOT/aliases/codex.zsh"

set +e
codex exec --no-alt-screen "hello world"
rc=$?
set -e

[[ "$rc" -eq 37 ]] || { print -u2 "expected Codex exit code 37, got $rc"; exit 1; }
expected=(-p local exec --no-alt-screen "hello world")
actual=("${(@f)$(<"$CODEX_TEST_ARGS_FILE")}")
[[ "${actual[*]}" == "${expected[*]}" ]] || {
  print -u2 "expected argv: ${expected[*]}"
  print -u2 "actual argv: ${actual[*]}"
  exit 1
}

print "PASS: local profile injection and exit-code propagation"
