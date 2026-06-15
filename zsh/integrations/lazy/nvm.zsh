export NVM_DIR="$HOME/.nvm"

__load_nvm() {
  if [[ "$__NVM_LOADED" == "1" ]]; then
    export __NVM_LOADED=1
    return 0
  fi

  local nvm_script=""
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    nvm_script="$NVM_DIR/nvm.sh"
  elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    nvm_script="/opt/homebrew/opt/nvm/nvm.sh"
  fi

  if [ -z "$nvm_script" ]; then
    return 1
  fi

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
    echo "nvm loader not found: $NVM_DIR/nvm.sh or /opt/homebrew/opt/nvm/nvm.sh" >&2
    return 127
  fi
  if ! typeset -f nvm >/dev/null 2>&1; then
    echo "nvm function failed to load from: $NVM_DIR/nvm.sh or /opt/homebrew/opt/nvm/nvm.sh" >&2
    return 127
  fi
  nvm "$@"
}
