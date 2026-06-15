if [[ -r "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview '
  if command -v colorls >/dev/null 2>&1; then
    colorls -1 --gs --sd "$realpath"
  elif command -v eza >/dev/null 2>&1; then
    eza -1 --color=always "$realpath"
  else
    ls -laG "$realpath"
  fi
'
