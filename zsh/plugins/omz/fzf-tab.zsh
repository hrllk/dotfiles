fzf_tab_plugin="$ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh"

# fzf-tab needs the fzf executable at runtime. Keep normal zsh completion
# available when the optional dependency is not installed yet.
if (( $+commands[fzf] )) && [[ -r "$fzf_tab_plugin" ]]; then
  source "$fzf_tab_plugin"

  # Let fzf-tab own the completion menu instead of zsh's select menu.
  zstyle ':completion:*' menu no
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
fi

unset fzf_tab_plugin
