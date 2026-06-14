set -o vi

bindkey -M viins '^?' vi-backward-delete-char
bindkey -M viins '^H' vi-backward-delete-char
bindkey -M emacs '^?' backward-delete-char
bindkey -M emacs '^H' backward-delete-char
