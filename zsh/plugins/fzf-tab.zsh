if [[ -r "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

_fzf_tab_preview_cd() {
  local target="$1"

  if command -v colorls >/dev/null 2>&1; then
    colorls -1 --gs --sd "$target"
  elif command -v eza >/dev/null 2>&1; then
    eza -1 --color=always "$target"
  else
    ls -laG "$target"
  fi
}

zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview '_fzf_tab_preview_cd $realpath'
