export DOTFILES_KEY_DIR="${DOTFILES_KEY_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/task/keys}"

__export_secret() {
  local name="$1"
  local path="$2"
  local value

  if [[ ! -r "$path" ]]; then
    echo "secret file not readable: $path" >&2
    return 1
  fi

  IFS= read -r value < "$path"
  export "$name=$value"
}
