#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM_DIR:-$HOME/.oh-my-zsh/custom}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.dotfiles-backup}"
TMUX_TPM_DIR="$HOME/.local/share/tmux/plugins/tpm"

DRY_RUN=0
SHELL_ONLY=0
AI=0
SYNC_SECRETS=0
BACKUP_TIMESTAMP="${BACKUP_TIMESTAMP:-}"

usage() {
  cat <<'USAGE'
usage: bootstrap.sh [--shell-only] [--dry-run] [--ai [--sync-secrets]]

  no args                 same as --shell-only
  --shell-only            clone/backup/link shell and terminal configuration
  --ai                    link Claude/Hermes AI configuration and print Codex guidance
  --sync-secrets          sync Hermes runtime secrets; requires --ai
  --dry-run               print actions without network or filesystem mutation
  --help                  print this help
USAGE
}

error() {
  printf 'bootstrap: %s\n' "$*" >&2
}

safe_label() {
  basename -- "$1"
}

now_timestamp() {
  date +%Y%m%d-%H%M%S
}

parse_args() {
  local arg
  while (( $# )); do
    arg="$1"
    case "$arg" in
      --dry-run)
        (( DRY_RUN == 0 )) || { error 'invalid arguments'; return 2; }
        DRY_RUN=1
        ;;
      --shell-only)
        (( SHELL_ONLY == 0 )) || { error 'invalid arguments'; return 2; }
        SHELL_ONLY=1
        ;;
      --ai)
        (( AI == 0 )) || { error 'invalid arguments'; return 2; }
        AI=1
        ;;
      --sync-secrets)
        (( SYNC_SECRETS == 0 )) || { error 'invalid arguments'; return 2; }
        SYNC_SECRETS=1
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error "invalid arguments: $arg"
        return 2
        ;;
    esac
    shift
  done
}

validate_combination() {
  if (( AI && SHELL_ONLY )); then
    error 'invalid combination: --ai cannot be combined with --shell-only'
    return 2
  fi
  if (( SYNC_SECRETS && !AI )); then
    error 'invalid combination: --sync-secrets requires --ai'
    return 2
  fi
}

resolve_timestamp() {
  if [[ -z "$BACKUP_TIMESTAMP" ]]; then
    BACKUP_TIMESTAMP="$(now_timestamp)"
  fi
  [[ "$BACKUP_TIMESTAMP" =~ ^[0-9]{8}-[0-9]{6}$ ]] || {
    error 'invalid BACKUP_TIMESTAMP; expected YYYYMMDD-HHMMSS'
    return 2
  }
  export BACKUP_TIMESTAMP BACKUP_ROOT
}

run_command() {
  if (( DRY_RUN )); then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

backup_path_for() {
  local target="$1"
  local base="$(safe_label "$target")"
  local candidate="$HOME/${base}.bak.${BACKUP_TIMESTAMP}"
  local suffix=0

  while [[ -e "$candidate" || -L "$candidate" ]]; do
    suffix=$((suffix + 1))
    candidate="$BACKUP_ROOT/${base}.bak.${BACKUP_TIMESTAMP}.${suffix}"
  done
  printf '%s\n' "$candidate"
}

backup_with_timestamp() {
  local target="$1"
  local backup_path
  backup_path="$(backup_path_for "$target")"
  run_command mkdir -p "$(dirname "$backup_path")"
  run_command mv "$target" "$backup_path"
  printf 'backup: %s -> %s\n' "$(safe_label "$target")" "$(safe_label "$backup_path")"
}

link_path() {
  local source_path="$1"
  local target_path="$2"

  if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
    return 0
  fi
  if [[ -L "$target_path" || -e "$target_path" ]]; then
    backup_with_timestamp "$target_path"
  fi
  run_command mkdir -p "$(dirname "$target_path")"
  run_command ln -s "$source_path" "$target_path"
}

clone_if_missing() {
  local repo="$1"
  local target="$2"
  local depth="${3:-}"

  [[ -d "$target/.git" ]] && return 0
  [[ -e "$target" ]] && backup_with_timestamp "$target"
  run_command mkdir -p "$(dirname "$target")"
  if [[ -n "$depth" ]]; then
    run_command git clone --depth "$depth" "$repo" "$target"
  else
    run_command git clone "$repo" "$target"
  fi
}

preflight_shell() {
  [[ -d "$DOTFILES_DIR/zsh" ]] || { error 'missing shell source directory'; return 10; }
  command -v git >/dev/null 2>&1 || { error 'missing prerequisite: git'; return 10; }
  command -v ln >/dev/null 2>&1 || { error 'missing prerequisite: ln'; return 10; }
  command -v mv >/dev/null 2>&1 || { error 'missing prerequisite: mv'; return 10; }
  command -v mkdir >/dev/null 2>&1 || { error 'missing prerequisite: mkdir'; return 10; }
}

preflight_ai() {
  [[ -d "$DOTFILES_DIR/ai/.claude" ]] || { error 'missing Claude source directory'; return 10; }
  [[ -d "$DOTFILES_DIR/ai/.hermes" ]] || { error 'missing Hermes source directory'; return 10; }
  command -v ln >/dev/null 2>&1 || { error 'missing prerequisite: ln'; return 10; }
  command -v mv >/dev/null 2>&1 || { error 'missing prerequisite: mv'; return 10; }
  command -v mkdir >/dev/null 2>&1 || { error 'missing prerequisite: mkdir'; return 10; }
  command -v rsync >/dev/null 2>&1 || { error 'missing prerequisite: rsync'; return 10; }
}

preflight_sync() {
  [[ -x "$DOTFILES_DIR/ai/.hermes/scripts/sync-secrets" ]] || { error 'missing sync-secrets'; return 10; }
  return 0
}

run_shell_stage() {
  clone_if_missing https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k" 1 || { error 'file-link failure: powerlevel10k'; return 20; }
  clone_if_missing https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM_DIR/plugins/fzf-tab" || { error 'file-link failure: fzf-tab'; return 20; }
  clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" || { error 'file-link failure: zsh-autosuggestions'; return 20; }
  clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" || { error 'file-link failure: zsh-syntax-highlighting'; return 20; }
  clone_if_missing https://github.com/tmux-plugins/tpm "$TMUX_TPM_DIR" || { error 'file-link failure: tpm'; return 20; }

  link_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc" || return 20
  link_path "$DOTFILES_DIR/util/jetbrains/.ideavimrc" "$HOME/.ideavimrc" || return 20
  link_path "$DOTFILES_DIR/util/tmux/.tmux.conf" "$HOME/.tmux.conf" || return 20
  link_path "$DOTFILES_DIR/util/tmux/.gitmux.conf" "$HOME/.gitmux.conf" || return 20
  link_path "$DOTFILES_DIR/util/tmux/.tmux" "$HOME/.tmux" || return 20
  link_path "$DOTFILES_DIR/util/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf" || return 20
  link_path "$DOTFILES_DIR/util/wezterm/wezterm.lua" "$HOME/.wezterm.lua" || return 20
}

run_ai_stage() {
  local claude_helper="$DOTFILES_DIR/ai/.claude/scripts/link-claude-home"
  local claude_args=(--yes)
  (( DRY_RUN )) && claude_args=(--dry-run)

  BACKUP_ROOT="$BACKUP_ROOT" BACKUP_TIMESTAMP="$BACKUP_TIMESTAMP" DOTFILES_DIR="$DOTFILES_DIR" \
    "$claude_helper" "${claude_args[@]}" || { error 'file-link failure: Claude'; return 20; }
  link_path "$DOTFILES_DIR/ai/.hermes" "$HOME/.hermes" || return 20
  printf 'Codex local profile guidance: create %s/local.config.toml explicitly; no automatic copy or link was performed.\n' "$HOME/.codex"
}

run_sync_stage() {
  (( DRY_RUN )) && { printf 'dry-run: would sync Hermes secrets\n'; return 0; }
  "$DOTFILES_DIR/ai/.hermes/scripts/sync-secrets" || { error 'sync failure'; return 30; }
}

main() {
  parse_args "$@" || return $?
  validate_combination || return $?
  resolve_timestamp || return $?

  if (( !AI )); then
    preflight_shell || return $?
    run_shell_stage || return $?
  else
    preflight_ai || return $?
    run_ai_stage || return $?
    if (( SYNC_SECRETS )); then
      preflight_sync || return $?
      run_sync_stage || return $?
    fi
  fi

  printf 'bootstrap completed. backups: %s timestamp: %s\n' "$BACKUP_ROOT" "$BACKUP_TIMESTAMP"
}

main "$@"
