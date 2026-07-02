if [[ -z "${ZSH_RELOADING_RC:-}" ]]; then
  # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
  # Initialization code that may require console input (password prompts, [y/n]
  # confirmations, etc.) must go above this block; everything else may go below.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
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
source_if_exists "$ZSH_DOTFILES_PATH/plugins/omz/theme.zsh"

autoload -Uz add-zsh-hook
zmodload -i zsh/stat

typeset -g _zshrc_mtime=''
typeset -g _p10k_mtime=''
typeset -A _zshrc_stat
zstat -H _zshrc_stat -L -- "$ZSH_DOTFILES_PATH/.zshrc" 2>/dev/null && _zshrc_mtime="${_zshrc_stat[mtime]}"
typeset -A _p10k_stat
zstat -H _p10k_stat -L -- "$ZSH_DOTFILES_PATH/.p10k.zsh" 2>/dev/null && _p10k_mtime="${_p10k_stat[mtime]}"

reload_zshrc() {
  local -A stat
  local -A p10k_stat

  zstat -H stat -L -- "$ZSH_DOTFILES_PATH/.zshrc" 2>/dev/null || return 0
  zstat -H p10k_stat -L -- "$ZSH_DOTFILES_PATH/.p10k.zsh" 2>/dev/null

  [[ "${stat[mtime]}" == "$_zshrc_mtime" && "${p10k_stat[mtime]:-}" == "$_p10k_mtime" ]] && return 0

  _zshrc_mtime="${stat[mtime]}"
  _p10k_mtime="${p10k_stat[mtime]:-}"
  ZSH_RELOADING_RC=1 source "$ZSH_DOTFILES_PATH/.zshrc"
  unset ZSH_RELOADING_RC
}

add-zsh-hook -d precmd reload_zshrc 2>/dev/null
add-zsh-hook precmd reload_zshrc

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/hrk/.sdkman"
[[ -s "/Users/hrk/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/hrk/.sdkman/bin/sdkman-init.sh"
