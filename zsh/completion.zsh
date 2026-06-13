autoload -Uz compinit

zcompdump="${ZDOTDIR:-$HOME}/.zcompdump-${HOST:-unknown}-${ZSH_VERSION}"

if [[ ! -s "$zcompdump" || "$zcompdump" -ot "$HOME/.zshrc" ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi
