# The Terminal Color Palette

## 1. Overview

In this article, we'll look at the palette shared by wezterm, tmux, and k9s,
the single meaning assigned to orange, and why the k9s skin cannot use the
palette literals.

The aim is that the only colored thing on screen is code. The chrome carries
one meaning.

## 2. The Palette

The values come from the nvim sonokai "andromeda" theme:

| Role | Value | Used for |
|---|---|---|
| orange | `#F89860` | wezterm border, tmux pane border, AI alert |
| dim orange | `#6B4226` | Inactive pane border, copy-mode selection |
| fg | `#E1E3E4` | Default foreground |
| grey | `#7E8294` | Inactive window names |
| grey dim | `#5A5E7A` | Status line of an unfocused terminal |

They are declared in the `sonokai` table in `util/wezterm/wezterm.lua` and at
the top of `util/tmux/.tmux.conf`. The two sets must match.

## 3. One Rule for Orange

In the tmux status line, orange means one thing: **this window wants you.**

| State | Color |
|---|---|
| Idle | `#7E8294` |
| Current window | `#E1E3E4` |
| `@ai_unread` | `#F89860` |
| `@ai_waiting` | `#F89860` + bold |

### 3.1. Why the Current Window Is Achromatic

The screen already shows which window we are in. Spending the only chromatic
color in the chrome on a fact we can already see leaves nothing to signal with.

Bold is reserved for "answer me", so weight does not dilute into "look here".

### 3.2. Bell and Activity Match

```tmux
set -g window-status-bell-style fg=#F89860
set -g window-status-activity-style fg=#F89860
```

The default is `reverse`, which flips foreground into background and renders a
block. A bell and `@ai_unread` mean the same thing and clear the same way, so
they should look the same.

## 4. Focus Lives in tmux, Not the Window Border

With several terminal windows open, the focused one is shown by status line
brightness:

```tmux
set-hook -g client-focus-in[97]  'set-option status-style bg=default,fg=#E1E3E4 ; set-option window-status-current-style fg=#E1E3E4'
set-hook -g client-focus-out[97] 'set-option status-style bg=default,fg=#5A5E7A ; set-option window-status-current-style fg=#5A5E7A'
```

The wezterm border stays orange.

### 4.1. Why Not the wezterm Border

The only API that changes a wezterm border is `set_config_overrides`, which
re-evaluates the whole configuration and rebuilds the window on the GUI
thread. Paying that on both windows at every switch stalls input for a beat.
Redrawing a status line is free by comparison.

### 4.2. One Terminal Window per tmux Session

The hooks call `set-option` without `-g`, so the value is written to the
session. Two windows attached to one session overwrite each other.

The AI orange is exempt from the dimming, because
`window-status-format` paints it directly. An unwatched terminal is exactly
where that signal is needed.

## 5. k9s Cannot Use the Palette Literals

`util/k9s/skins/sonokai-orange.yaml` uses the xterm-256 entries the palette
values *quantize to*, not the values themselves.

### 5.1. The Cause

k9s renders through tcell, and tcell decides truecolor from terminfo rather
than `COLORTERM`. Under `TERM=tmux-256color` it falls back to 256 colors, and
a color that sits between palette entries converts to something unrelated.

Measured on k9s 0.51.0:

```text
#F89860 -> #8787FF (purple)     #6DCAE8 -> #87AFAF (muddy cyan)
#6B4226 -> #8787AF              #7E8294 -> #87AFFF
```

### 5.2. The Fix

A color sitting exactly on an entry passes through. So the skin uses `#FF875F`
(entry 209) instead of `#F89860`, and `#875F00` (entry 94) instead of
`#6B4226`.

### 5.3. Measure, Do Not Eyeball

**When changing a color in this file, measure it.** Set only `body.logoColor`,
start k9s under a terminal capture, and read the SGR sequence that paints the
ASCII logo. The measurements in 5.1 were taken that way.

Comparing two hex values by eye proves nothing here, because the value tcell
renders is not the value in the file.

## 6. Trade-offs

- The wezterm border does not indicate focus. That bought switch latency.
- The k9s orange is `#FF875F`, slightly off tmux's `#F89860`. Since k9s drops
  to 256 colors anyway, the rendered result matches.
- The literals are duplicated across wezterm, tmux, and k9s. The formats
  differ, so changing one means checking the others.

## 7. Conclusion

In this article, we've seen a shared palette, one meaning for orange, focus
indicated in tmux for latency reasons, and a k9s skin written in quantized
values because tcell ignores `COLORTERM`.

Sources: `util/tmux/.tmux.conf`, `util/wezterm/wezterm.lua`,
`util/k9s/skins/sonokai-orange.yaml`.

Back to [Installing the Dotfiles](01-installing-the-dotfiles.md).
