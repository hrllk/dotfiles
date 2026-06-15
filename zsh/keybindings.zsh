set -o vi

zmodload -i zsh/terminfo
autoload -Uz add-zsh-hook

bind_completion_keys() {
  local backtab_key="${terminfo[kcbt]:-$'\e[Z'}"

  bindkey "$backtab_key" reverse-menu-complete
  bindkey -M viins "$backtab_key" reverse-menu-complete
  bindkey -M vicmd "$backtab_key" reverse-menu-complete
  bindkey -M emacs "$backtab_key" reverse-menu-complete
  bindkey -M menuselect "$backtab_key" reverse-menu-complete
}

add-zsh-hook -d precmd bind_completion_keys 2>/dev/null
add-zsh-hook precmd bind_completion_keys
bind_completion_keys

bindkey -M viins '^?' vi-backward-delete-char
bindkey -M viins '^H' vi-backward-delete-char
bindkey -M vicmd '^?' vi-backward-delete-char
bindkey -M vicmd '^H' vi-backward-delete-char
bindkey -M emacs '^?' backward-delete-char
bindkey -M emacs '^H' backward-delete-char
