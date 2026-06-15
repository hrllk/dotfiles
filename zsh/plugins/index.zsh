export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

plugin_configs=(
  "$ZSH_DOTFILES_PATH/plugins/safe-paste.zsh"
  "$ZSH_DOTFILES_PATH/plugins/autosuggestions.zsh"
  "$ZSH_DOTFILES_PATH/plugins/fzf-tab.zsh"
  "$ZSH_DOTFILES_PATH/plugins/syntax-highlighting.zsh"
)

for plugin_config in "${plugin_configs[@]}"; do
  [[ -r "$plugin_config" ]] && source "$plugin_config"
done

unset plugin_config plugin_configs
