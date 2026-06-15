export NVM_DIR="$HOME/.nvm"

__resolve_nvm_script() {
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    printf '%s\n' "$NVM_DIR/nvm.sh"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    local brew_nvm_prefix
    brew_nvm_prefix="$(brew --prefix nvm 2>/dev/null)" || true
    if [ -n "$brew_nvm_prefix" ] && [ -s "$brew_nvm_prefix/nvm.sh" ]; then
      printf '%s\n' "$brew_nvm_prefix/nvm.sh"
      return 0
    fi
  fi

  for candidate in /opt/homebrew/opt/nvm/nvm.sh /usr/local/opt/nvm/nvm.sh; do
    if [ -s "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

__load_nvm() {
  if [[ "$__NVM_LOADED" == "1" ]]; then
    export __NVM_LOADED=1
    return 0
  fi

  local nvm_script
  nvm_script="$(__resolve_nvm_script)" || return 1

  . "$nvm_script"
  if ! typeset -f nvm >/dev/null 2>&1; then
    return 1
  fi

  nvm use --silent default >/dev/null 2>&1 || nvm use --silent node >/dev/null 2>&1 || true
  export __NVM_LOADED=1
}

nvm() {
  unset -f nvm
  if ! __load_nvm; then
    echo "nvm loader not found: $NVM_DIR/nvm.sh, brew --prefix nvm, /opt/homebrew/opt/nvm/nvm.sh, or /usr/local/opt/nvm/nvm.sh" >&2
    return 127
  fi
  if ! typeset -f nvm >/dev/null 2>&1; then
    echo "nvm function failed to load from the resolved nvm script" >&2
    return 127
  fi
  nvm "$@"
}
