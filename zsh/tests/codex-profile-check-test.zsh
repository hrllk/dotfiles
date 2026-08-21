#!/usr/bin/env zsh
set -u
ROOT="${0:A:h:h:h}"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
mkdir -p "$TMP_HOME/.codex" "$TMP_HOME/workspace"
export HOME="$TMP_HOME" CODEX_HOME="$TMP_HOME/.codex"

cat > "$CODEX_HOME/local.config.toml" <<EOF
[projects."$TMP_HOME/workspace"]
trust_level = "trusted"
EOF
chmod 600 "$CODEX_HOME/local.config.toml"

"$ROOT/ai/.codex/codex-profile-check"

cat > "$CODEX_HOME/local.config.toml" <<EOF
[projects."$TMP_HOME/missing"]
trust_level = "trusted"
EOF
set +e
"$ROOT/ai/.codex/codex-profile-check" >/dev/null 2>"$TMP_HOME/error"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || exit 1
[[ "$(<"$TMP_HOME/error")" == *"does not exist"* ]] || exit 1

print "PASS: profile checker validates workspace existence"
