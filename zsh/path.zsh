typeset -gU path
path=(
  # Keep paths inherited from the launcher/shell. macOS tools such as Codex's
  # bundled rg can be provided there and must survive this PATH setup.
  /opt/homebrew/bin
  /opt/homebrew/opt/ripgrep/bin
  /usr/local/opt/ripgrep/bin
  /opt/homebrew/Caskroom/codex/*/codex-path(N)
  /opt/homebrew/opt/ruby/bin
  /opt/homebrew/opt/mysql-client/bin
  /opt/homebrew/opt/libpq/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $path
)

path+=(/opt/homebrew/lib/ruby/gems/*/bin(N))

if [[ -n "${JAVA_HOME:-}" ]]; then
  path+=(
    $JAVA_HOME/bin
  )
fi

path+=(
  /Applications/IntelliJ\ IDEA.app/Contents/MacOS
  $IMAGEMAGICK_HOME/bin
  /opt/homebrew/opt/kafka/bin
  $HOME/.rd/bin
  /usr/local/texlive/2025/bin/universal-darwin
  $HOME/.local/bin
  $BUN_INSTALL/bin
  $HOME/.antigravity/antigravity/bin
  /usr/local/bin
)

export PATH
rehash 2>/dev/null || true
