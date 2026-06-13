export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[[ ! -r "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme" ]] || source "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

prompt_context() {}
