#!/usr/bin/env bash
set -euo pipefail

# Smoke test for the shared AI-agent unread indicator.
# Exercises util/tmux/.tmux/scripts/ai-notify-hook.sh against an isolated tmux
# server so the developer's live session is never touched.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/util/tmux/.tmux/scripts/ai-notify-hook.sh"

[ -x "$HOOK" ] || { echo "missing hook: $HOOK" >&2; exit 1; }

TMUX_SOCKET="ai-unread-test-$$"
TMUX_CONF="$(mktemp "${TMPDIR:-/tmp}/ai-unread-tmux.XXXXXX.conf")"

cleanup() {
  tmux -L "$TMUX_SOCKET" kill-server >/dev/null 2>&1 || true
  rm -f "$TMUX_CONF"
}
trap cleanup EXIT

cat >"$TMUX_CONF" <<'CONF'
set -g status off
set -g window-status-current-format '#{?@ai_unread,#[fg=#FBBF24],} #I:#W #{?@ai_unread,#[fg=green],}'
set -g window-status-format '#{?@ai_unread,#[fg=#FBBF24],} #I:#W #{?@ai_unread,#[fg=colour250],}'
set-hook -g after-select-window[99] 'set-option -wq @ai_unread 0'
set-hook -g client-focus-in[99] 'set-option -wq @ai_unread 0'
CONF

tmux -L "$TMUX_SOCKET" -f "$TMUX_CONF" new-session -d -s test -n agent-a
tmux -L "$TMUX_SOCKET" new-window -d -t test:2 -n agent-b

socket_path="$(tmux -L "$TMUX_SOCKET" display-message -p '#{socket_path}')"
tmux_value="${socket_path},0,0"
pane_a="$(tmux -L "$TMUX_SOCKET" display-message -p -t test:agent-a '#{pane_id}')"
pane_b="$(tmux -L "$TMUX_SOCKET" display-message -p -t test:agent-b '#{pane_id}')"
window_a="$(tmux -L "$TMUX_SOCKET" display-message -p -t test:agent-a '#{window_id}')"
window_b="$(tmux -L "$TMUX_SOCKET" display-message -p -t test:agent-b '#{window_id}')"

unread_of() {
  tmux -L "$TMUX_SOCKET" show-options -wv -t "$1" @ai_unread 2>/dev/null || true
}

fire() {
  # fire <pane> <label> — runs the real hook and asserts a clean exit status.
  local rc=0
  TMUX="$tmux_value" TMUX_PANE="$2" "$HOOK" "$1" || rc=$?
  [ "$rc" -eq 0 ] || { echo "hook exited $rc for label $1" >&2; exit 1; }
}

# An inactive origin window is marked unread.
tmux -L "$TMUX_SOCKET" select-window -t test:agent-a
fire Codex "$pane_b"
[ "$(unread_of "$window_b")" = "1" ]

# The active origin window is already read.
fire Codex "$pane_a"
state="$(unread_of "$window_a")"
[ "$state" = "0" ] || [ -z "$state" ]

# Selecting the window clears the flag.
tmux -L "$TMUX_SOCKET" select-window -t test:agent-b
state="$(unread_of "$window_b")"
[ "$state" = "0" ] || [ -z "$state" ]

# Claude Code writes the same shared flag as Codex.
tmux -L "$TMUX_SOCKET" select-window -t test:agent-a
fire Claude "$pane_b"
[ "$(unread_of "$window_b")" = "1" ]

# Either agent's read event clears the other agent's mark.
tmux -L "$TMUX_SOCKET" select-window -t test:agent-b
state="$(unread_of "$window_b")"
[ "$state" = "0" ] || [ -z "$state" ]

# Reloading the configuration does not duplicate the fixed hook slot.
tmux -L "$TMUX_SOCKET" source-file "$TMUX_CONF"
hook_count="$(tmux -L "$TMUX_SOCKET" show-options -gH | grep -c 'after-select-window\[99\]' || true)"
[ "$hook_count" -eq 1 ]

# Outside tmux the hook is a silent no-op, and still exits 0. Claude Code reads
# exit code 2 as "keep going", so a non-zero exit here would be a live hazard.
rc=0
TMUX= TMUX_PANE= "$HOOK" Claude || rc=$?
[ "$rc" -eq 0 ] || { echo "outside-tmux hook exited $rc" >&2; exit 1; }

# A missing label must not trip `set -u`.
rc=0
TMUX= TMUX_PANE= "$HOOK" || rc=$?
[ "$rc" -eq 0 ] || { echo "no-label hook exited $rc" >&2; exit 1; }

echo "tmux unread smoke test passed"
