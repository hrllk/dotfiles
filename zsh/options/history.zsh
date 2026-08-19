# Persist and share command history across Zsh sessions.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=20000

# Save each command after it finishes without merging other sessions into
# the current shell's in-memory history.
setopt INC_APPEND_HISTORY_TIME

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE

# Zsh does not always import an existing file when history options are enabled
# from .zshrc, so load it once at startup. The guard also keeps .zshrc reloads
# from duplicating the in-memory history.
if (( ! ${#history} )) && [[ -r "$HISTFILE" ]]; then
  fc -R "$HISTFILE"
fi
