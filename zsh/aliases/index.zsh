for alias_file in \
  "$ZSH_DOTFILES_PATH/aliases/navigation.zsh" \
  "$ZSH_DOTFILES_PATH/aliases/git.zsh" \
  "$ZSH_DOTFILES_PATH/aliases/taskmaster.zsh" \
  "$ZSH_DOTFILES_PATH/aliases/tools.zsh" \
  "$ZSH_DOTFILES_PATH/aliases/others.zsh" \
  "$ZSH_DOTFILES_PATH/aliases/work.zsh"
do
  [[ -r "$alias_file" ]] && source "$alias_file"
done

unset alias_file
