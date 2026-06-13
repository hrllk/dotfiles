# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

autoload -Uz compinit
zcompdump="${ZDOTDIR:-$HOME}/.zcompdump-${HOST:-unknown}-${ZSH_VERSION}"

if [[ ! -s "$zcompdump" || "$zcompdump" -ot "$HOME/.zshrc" ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi

if [[ -r "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi



export LANG='en_US.UTF-8' 
export LC_ALL=en_US.UTF-8

export DOT_PATH="$HOME/dotfiles"

## shortcut 
if [ -f $DOT_PATH/.aliases ];
	then source $DOT_PATH/.aliases;
fi

if [ -f $DOT_PATH/.paths ];
	then source $DOT_PATH/.paths;
fi
if [ -f $DOT_PATH/.env_vars ];
	then source $DOT_PATH/.env_vars;
fi

if [ -f $DOT_PATH/.oke_vars ];
	then source $DOT_PATH/.oke_vars;
fi
if [ -f $DOT_PATH/.aliases_work ];
	then source $DOT_PATH/.aliases_work;
fi
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; 
if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; 
	then . "${___MY_VMOPTIONS_SHELL_FILE}"; 
fi



set -o vi



#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
__load_sdkman() {
  if [[ "$__SDKMAN_LOADED" == "1" ]]; then
    return 0
  fi

  if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "sdkman loader not found: $SDKMAN_DIR/bin/sdkman-init.sh" >&2
    return 127
  fi

  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  export __SDKMAN_LOADED=1
}

sdk() {
  unset -f sdk
  __load_sdkman || return $?
  sdk "$@"
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -r "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme" ]] || source "$ZSH_CUSTOM/themes/powerlevel10k/powerlevel10k.zsh-theme"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
prompt_context() {}

if [[ -r "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
# export PATH="/Users/hwiryungkim/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# # Default Editor
# if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
#     export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
# else
#     export VISUAL="nvim"
# fi
#
# export EDITOR="$VISUAL"
