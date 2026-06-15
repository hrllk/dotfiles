# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOT_PATH="$HOME/dotfiles"
export ZSH_DOTFILES_PATH="$DOT_PATH/zsh"

source_if_exists() {
  [[ -r "$1" ]] && source "$1"
}

source_if_exists "$ZSH_DOTFILES_PATH/options/completion.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/env.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/integrations/lazy/nvm.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/integrations/lazy/node-commands.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/secrets/index.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/aliases/index.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/integrations/lazy/sdkman.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/plugins/index.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/options/keybindings.zsh"
source_if_exists "$ZSH_DOTFILES_PATH/plugins/omz/prompt.zsh"
