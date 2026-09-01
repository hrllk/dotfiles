#!/usr/bin/env bash
set -u

# Shared tmux state hook for AI coding agents.
#
# Registered by both Codex (~/.codex/hooks.json) and Claude Code
# (~/.claude/settings.json). Both write window-scoped flags; .tmux.conf
# renders them and clears them on window select or client focus.
#
# usage: ai-notify-hook.sh <AgentLabel> [done|waiting]
#
#   done     the turn ended            -> @ai_unread  (amber)
#   waiting  the agent blocks on you    -> @ai_waiting (wine badge)
#
# "waiting" covers permission prompts and the AskUserQuestion dialog alike:
# Claude Code routes every requiresUserInteraction tool through the same ask
# path, so both surface as a permission_prompt notification.
#
# Agent hooks must not write to stdout or stderr.
exec >/dev/null 2>&1

label="${1:-Agent}"
state="${2:-done}"

# A run outside tmux has no window to mark.
[ -n "${TMUX:-}" ] || exit 0

pane="${TMUX_PANE:-}"
if [ -n "$pane" ]; then
  win="$(tmux display-message -p -t "$pane" '#{window_id}')" || exit 0
else
  win="$(tmux display-message -p '#{window_id}')" || exit 0
fi

[ -n "$win" ] || exit 0

# Keep the state at window scope. A run that reaches the active window is
# already visible and must be treated as read immediately.
active="$(tmux display-message -p -t "$win" '#{window_active}')" || exit 0

if [ "$active" = "1" ]; then
  tmux set-option -wq -t "$win" @ai_unread 0 || exit 0
  tmux set-option -wq -t "$win" @ai_waiting 0 || exit 0
else
  if [ "$state" = "waiting" ]; then
    # The turn has not ended, so leave @ai_unread alone; waiting outranks it
    # in the status format either way.
    tmux set-option -wq -t "$win" @ai_waiting 1 || exit 0
    message="$label needs your answer"
    body="답변을 기다리고 있습니다"
  else
    tmux set-option -wq -t "$win" @ai_unread 1 || exit 0
    # The turn is over: whatever it was blocked on has been answered.
    tmux set-option -wq -t "$win" @ai_waiting 0 || exit 0
    message="$label finished"
    body="작업이 완료되었습니다"
  fi

  # Only an unattended window earns an interruption. Claude Code fires Stop on
  # every assistant turn, so announcing the active window would flood the
  # status line and the desktop notification centre.
  tmux display-message -t "$win" "$message" || true

  if command -v kitten >/dev/null 2>&1; then
    kitten notify --identifier "ai-${label}-${state}-${win}" "$label" "$body" || true
  fi
fi

tmux refresh-client -S || true

# Claude Code reads exit code 2 as "block" — a deny on PermissionRequest, and
# stderr fed back to the model on Stop. Never leave the exit status to chance.
exit 0
