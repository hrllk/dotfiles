# AI Agent Notifications in tmux

## 1. Overview

In this article, we'll see how Codex and Claude Code mark the tmux window they
are running in, so an agent finishing in a background window is visible
without switching to it.

Both agents call the same hook script. The window turns orange when it wants
us.

## 2. The Two Flags

The hook sets one of two window-scoped options:

| Option | Meaning |
|---|---|
| `@ai_unread` | The turn ended and we have not looked yet |
| `@ai_waiting` | The agent is blocked on our answer |

There is no per-agent flag. The useful fact is that *this window* wants us; the
window name already says which agent.

## 3. Registering the Hook

Both agents point at the same script:

```text
Codex        ai/.codex/hooks.json
Claude Code  ai/.claude/settings.json  ->  hooks.Stop
```

Both paths reach the repository through the `~/.codex` and `~/.claude`
symlinks, so there is one copy of the script.

Its interface:

```bash
ai-notify-hook.sh <AgentLabel> [done|waiting]
```

## 4. What the Hook Does

It exits immediately outside tmux:

```bash
[ -n "${TMUX:-}" ] || exit 0
```

Then it resolves the window from `TMUX_PANE` and checks whether that window is
active:

```bash
active="$(tmux display-message -p -t "$win" '#{window_active}')" || exit 0
```

### 4.1. An Active Window Is Already Read

If the window is active, both flags are cleared and nothing is announced:

```bash
tmux set-option -wq -t "$win" @ai_unread 0
tmux set-option -wq -t "$win" @ai_waiting 0
```

Claude Code fires `Stop` on every assistant turn. Announcing the window we are
watching would overwrite the status line continuously.

### 4.2. An Inactive Window Gets a Flag and a Notification

```bash
tmux display-message -t "$win" "$message"
kitten notify --identifier "ai-${label}-${state}-${win}" "$label" "$body"
```

The desktop notification is best-effort; it runs only when `kitten` is on
`PATH`.

### 4.3. Two Things the Hook Must Never Do

It must not write to stdout or stderr, so the script redirects both at the top:

```bash
exec >/dev/null 2>&1
```

And it must not exit non-zero. Claude Code reads exit code `2` as "block": a
deny on `PermissionRequest`, and stderr fed back to the model on `Stop`. The
script ends with an explicit `exit 0`.

## 5. Rendering the Flags

`.tmux.conf` paints the flags in the window status, with `@ai_waiting` winning:

```tmux
set -g window-status-format '#{?@ai_waiting,#[fg=#F89860#,bold],#{?@ai_unread,#[fg=#F89860],}} #I:#W '
```

Keeping state and rendering separate means the existing
`window-status-style` is not overwritten.

## 6. Clearing Takes Three Hooks

```tmux
set-hook -g session-window-changed[99] 'set-option -wq @ai_unread 0 ; set-option -wq @ai_waiting 0'
set-hook -g client-session-changed[99] 'set-option -wq @ai_unread 0 ; set-option -wq @ai_waiting 0'
set-hook -g client-focus-in[99]        'set-option -wq @ai_unread 0 ; set-option -wq @ai_waiting 0'
```

**None of the three is redundant.** Each covers an arrival path the others
miss:

| Hook | Covers |
|---|---|
| `session-window-changed` | The session's current window moved |
| `client-session-changed` | The client moved to another session |
| `client-focus-in` | The terminal regained focus without any move |

A single `after-select-window` is not enough: it does not fire on
`switch-client`, and `session-window-changed` does not fire when we jump to a
session already sitting on the target window.

## 7. Verification

```zsh
bash scripts/tests/tmux-unread-test.sh
```

The test runs against an isolated tmux server, so it does not touch a running
session.

## 8. Conclusion

In this article, we've seen two shared flags, one script registered by both
agents, a rule that an active window is read on arrival, and three clearing
hooks that together cover every way of reaching a window.

Sources: `util/tmux/.tmux/scripts/ai-notify-hook.sh`, `util/tmux/.tmux.conf`.

Next: [The Terminal Color Palette](05-the-terminal-color-palette.md).
