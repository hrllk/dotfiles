typeset -gU path

path_add() {
  local dir
  for dir in "$@"; do
    [[ -d "$dir" ]] && path+=("$dir")
  done
}

# Keep inherited PATH entries in their original relative order. The explicit
# entries below are appended in this order, then zsh removes duplicates.
path_add \
  /opt/homebrew/bin \
  /opt/homebrew/opt/ripgrep/bin \
  /usr/local/opt/ripgrep/bin \
  /opt/homebrew/Caskroom/codex/*/codex-path(N) \
  /opt/homebrew/opt/ruby/bin \
  /opt/homebrew/opt/mysql-client/bin \
  /opt/homebrew/opt/libpq/bin \
  /opt/homebrew/lib/ruby/gems/*/bin(N) \
  /Applications/IntelliJ\ IDEA.app/Contents/MacOS

if [[ -n "${IMAGEMAGICK_HOME:-}" ]]; then
  path_add "$IMAGEMAGICK_HOME/bin"
fi

path_add \
  /opt/homebrew/opt/kafka/bin \
  "$HOME/.rd/bin" \
  /usr/local/texlive/2025/bin/universal-darwin \
  "$HOME/.local/bin" \
  "${BUN_BIN_DIR:-${BUN_INSTALL:-$HOME/.bun}/bin}" \
  "$HOME/.antigravity/antigravity/bin" \
  /usr/local/bin

if [[ -n "${JAVA_HOME:-}" ]]; then
  path_add "$JAVA_HOME/bin"
fi

if [[ -n "${RUBY_SHIMS_DIR:-}" && -d "$RUBY_SHIMS_DIR" ]]; then
  path=("$RUBY_SHIMS_DIR" "${path[@]}")
fi

path=("${(@u)path}")
export PATH
rehash 2>/dev/null || true
unfunction path_add 2>/dev/null
