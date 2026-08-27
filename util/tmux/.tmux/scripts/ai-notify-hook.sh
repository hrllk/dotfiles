#!/usr/bin/env bash
set -u

# Shared tmux completion hook for AI coding agents.
#
# Registered by both Codex (~/.codex/hooks.json) and Claude Code
# (~/.claude/settings.json) on their respective Stop events. Both write the
# same window-scoped @ai_unread flag; .tmux.conf renders it and clears it on
# window select or client focus.
#
# usage: ai-notify-hook.sh <AgentLabel>
#
# Agent Stop hooks must not write to stdout or stderr.
exec >/dev/null 2>&1

label="${1:-Agent}"

# A run outside tmux has no window to mark.
[ -n "${TMUX:-}" ] || exit 0

pane="${TMUX_PANE:-}"
if [ -n "$pane" ]; then
  win="$(tmux display-message -p -t "$pane" '#{window_id}')" || exit 0
else
  win="$(tmux display-message -p '#{window_id}')" || exit 0
fi

[ -n "$win" ] || exit 0

# Keep the state at window scope. A run that finishes in the active window is
# already visible and must be treated as read immediately.
active="$(tmux display-message -p -t "$win" '#{window_active}')" || exit 0

if [ "$active" = "1" ]; then
  tmux set-option -wq -t "$win" @ai_unread 0 || exit 0
else
  tmux set-option -wq -t "$win" @ai_unread 1 || exit 0

  # Only an unattended window earns an interruption. Claude Code fires Stop on
  # every assistant turn, so announcing the active window would flood the
  # status line and the desktop notification centre.
  tmux display-message -t "$win" "$label finished" || true

  if command -v kitten >/dev/null 2>&1; then
    kitten notify --identifier "ai-${label}-${win}" "$label" "작업이 완료되었습니다" || true
  fi
fi

tmux refresh-client -S || true

# Claude Code reads exit code 2 as "block the stop and feed stderr back to the
# model". Never leave the exit status to chance here.
exit 0
