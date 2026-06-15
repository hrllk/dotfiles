export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

custom_plugin_configs=(
  "$ZSH_DOTFILES_PATH/plugins/custom/safe-paste.zsh"
)

omz_plugin_configs=(
  "$ZSH_DOTFILES_PATH/plugins/omz/autosuggestions.zsh"
  "$ZSH_DOTFILES_PATH/plugins/omz/fzf-tab.zsh"
  "$ZSH_DOTFILES_PATH/plugins/omz/syntax-highlighting.zsh"
)

for plugin_config in "${custom_plugin_configs[@]}"; do
  [[ -r "$plugin_config" ]] && source "$plugin_config"
done

for plugin_config in "${omz_plugin_configs[@]}"; do
  [[ -r "$plugin_config" ]] && source "$plugin_config"
done

unset plugin_config custom_plugin_configs omz_plugin_configs
