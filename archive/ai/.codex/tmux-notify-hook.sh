#!/usr/bin/env bash
set -euo pipefail

# Codex Stop hook은 stdout plain text를 내보내면 안 되므로 조용히 실행
exec >/dev/null 2>&1

# tmux 밖이면 종료
[ -n "${TMUX:-}" ] || exit 0

pane="${TMUX_PANE:-}"

if [ -n "$pane" ]; then
  win="$(tmux display-message -p -t "$pane" '#{window_id}')"
else
  win="$(tmux display-message -p '#{window_id}')"
fi

# 해당 window를 완료 상태처럼 강조
tmux set-option -w -t "$win" window-status-style 'fg=colour232,bg=colour220,bold'

# tmux status message
if [ -n "$pane" ]; then
  tmux display-message -t "$pane" 'Codex finished'
else
  tmux display-message 'Codex finished'
fi

# kitty desktop notification
if command -v kitten >/dev/null 2>&1; then
  kitten notify --identifier "codex-${win}" "Codex" "작업이 완료되었습니다" || true
fi

tmux refresh-client -S || true
