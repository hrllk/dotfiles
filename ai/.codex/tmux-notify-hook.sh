#!/usr/bin/env bash
set -u

# Codex Stop hook must not write to stdout or stderr.
exec >/dev/null 2>&1

# A Codex run outside tmux has no window to mark.
[ -n "${TMUX:-}" ] || exit 0

pane="${TMUX_PANE:-}"
if [ -n "$pane" ]; then
  win="$(tmux display-message -p -t "$pane" '#{window_id}')" || exit 0
else
  win="$(tmux display-message -p '#{window_id}')" || exit 0
fi

[ -n "$win" ] || exit 0

# Keep the state at window scope. If Codex finishes in the active window,
# the result is already visible and must be treated as read immediately.
active="$(tmux display-message -p -t "$win" '#{window_active}')" || exit 0
if [ "$active" = "1" ]; then
  tmux set-option -wq -t "$win" @codex_unread 0 || exit 0
else
  tmux set-option -wq -t "$win" @codex_unread 1 || exit 0
fi

if [ -n "$pane" ]; then
  tmux display-message -t "$pane" 'Codex finished' || true
else
  tmux display-message -t "$win" 'Codex finished' || true
fi

if command -v kitten >/dev/null 2>&1; then
  kitten notify --identifier "codex-${win}" "Codex" "작업이 완료되었습니다" || true
fi

tmux refresh-client -S || true
