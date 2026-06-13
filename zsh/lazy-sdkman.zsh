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
