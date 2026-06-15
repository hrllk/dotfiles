setopt GLOB_DOTS

zmodload -i zsh/complist

autoload -Uz compinit

zstyle ':completion:*' menu select=1
zstyle ':completion:*' descriptions format '[%d]'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-packed false
zstyle ':completion:*' list-rows-first true
zstyle ':completion:*' list-dirs-first true

zcompdump="${ZDOTDIR:-$HOME}/.zcompdump-${HOST:-unknown}-${ZSH_VERSION}"

if [[ ! -s "$zcompdump" || "$zcompdump" -ot "$HOME/.zshrc" || "$zcompdump" -ot "$ZSH_DOTFILES_PATH/options/completion.zsh" ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi
