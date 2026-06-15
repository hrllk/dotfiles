#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM_DIR:-$HOME/.oh-my-zsh/custom}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

mkdir -p "$BACKUP_ROOT"

backup_with_timestamp() {
  local path="$1"
  local base_name="${2:-$(basename "$path")}"
  local stamp
  local backup_path

  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_path="$HOME/${base_name}.bak.${stamp}"

  if [[ -e "$backup_path" || -L "$backup_path" ]]; then
    backup_path="$BACKUP_ROOT/${base_name}.bak.${stamp}"
  fi

  mv "$path" "$backup_path"
}

backup_path() {
  local path="$1"
  local name="${2:-$(basename "$path")}"

  if [[ -e "$path" || -L "$path" ]]; then
    mkdir -p "$BACKUP_ROOT"
    mv "$path" "$BACKUP_ROOT/$name"
  fi
}

link_path() {
  local source_path="$1"
  local target_path="$2"

  if [[ -L "$target_path" ]]; then
    if [[ "$(readlink "$target_path")" == "$source_path" ]]; then
      return 0
    fi
    backup_path "$target_path" "$(basename "$target_path")"
  elif [[ -e "$target_path" ]]; then
    backup_path "$target_path" "$(basename "$target_path")"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
}

write_zshrc_entrypoint() {
  local target_path="$HOME/.zshrc"
  local target_content='source ~/dotfiles/zsh/.zshrc'

  if [[ -L "$target_path" || -e "$target_path" ]]; then
    if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "./dotfiles/.zshrc" ]]; then
      backup_with_timestamp "$target_path" ".zshrc"
    elif [[ -f "$target_path" ]] && [[ "$(cat "$target_path")" == "$target_content" ]]; then
      return 0
    else
      backup_with_timestamp "$target_path" ".zshrc"
    fi
  fi

  printf '%s\n' "$target_content" > "$target_path"
}

clone_if_missing() {
  local repo="$1"
  local target="$2"
  local depth="${3:-}"

  if [[ -d "$target/.git" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  if [[ -n "$depth" ]]; then
    git clone --depth "$depth" "$repo" "$target"
  else
    git clone "$repo" "$target"
  fi
}

clone_if_missing https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k" 1
clone_if_missing https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM_DIR/plugins/fzf-tab"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

write_zshrc_entrypoint
link_path "$DOTFILES_DIR/util/tmux/.tmux.conf" "$HOME/.tmux.conf"
link_path "$DOTFILES_DIR/util/tmux/.gitmux.conf" "$HOME/.gitmux.conf"
link_path "$DOTFILES_DIR/util/tmux/.tmux" "$HOME/.tmux"
link_path "$DOTFILES_DIR/util/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

printf 'bootstrap completed. backups: %s\n' "$BACKUP_ROOT"
