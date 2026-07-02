export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

[[ ! -r "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme" ]] || source "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme"
[[ ! -f "$ZSH_DOTFILES_PATH/.p10k.zsh" ]] || source "$ZSH_DOTFILES_PATH/.p10k.zsh"

prompt_context() {}
