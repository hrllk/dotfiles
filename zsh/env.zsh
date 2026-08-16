export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
export EDITOR="nvim"

# =============================================================================
# 1. Global path declaration
# =============================================================================
#
# zsh keeps the `path` array and the exported `PATH` variable in sync.
# `-U` removes duplicates, while leaving the inherited PATH intact.
typeset -gU path
# Normalize duplicates that may already exist in the inherited PATH.
path=("${(@u)path}")

path_add() {
  local dir

  for dir in "$@"; do
    [[ -d "$dir" ]] && path+=("$dir")
  done
}

# =============================================================================
# 2. Documented paths
# =============================================================================

# System paths.
path_add \
  /opt/homebrew/bin \
  /usr/local/bin \
  /usr/bin \
  /bin \
  /usr/sbin \
  /sbin

# Toolchain and user-installed binaries.
path_add \
  /opt/homebrew/opt/mysql-client/bin \
  /opt/homebrew/opt/kafka/bin \
  "$HOME/.rd/bin" \
  /usr/local/texlive/2025/bin/universal-darwin \
  "$HOME/.local/bin"

# Ruby gems installed by Homebrew.
path_add /opt/homebrew/lib/ruby/gems/*/bin(N)

# =============================================================================
# 3. Explicit precedence policy
# =============================================================================

# rbenv intentionally prepends its shims so the selected Ruby version wins.
# Other tools retain the inherited/documented PATH order until an explicit
# per-tool policy is added.

if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
  path=("${(@u)path}")
fi

# =============================================================================
# 4. Tool homes and dependent paths
# =============================================================================

export MAVEN_HOME=/opt/homebrew/Cellar/maven/3.9.9/libexec
export GRADLE_HOME="$HOME/task/tmp/gradle-8.10.2"
export IMAGEMAGICK_HOME=/opt/homebrew/var/homebrew/linked/imagemagick
export DYLD_FALLBACK_LIBRARY_PATH="$IMAGEMAGICK_HOME/lib"
export BUN_INSTALL="$HOME/.bun"

if [[ -x "$HOME/.sdkman/candidates/java/current/bin/java" ]]; then
  export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
else
  local_java_home="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  if [[ -n "$local_java_home" ]]; then
    export JAVA_HOME="$local_java_home"
  fi
fi

path_add \
  "$IMAGEMAGICK_HOME/bin" \
  "$BUN_INSTALL/bin"

[[ -n "${JAVA_HOME:-}" ]] && path_add "$JAVA_HOME/bin"

if [[ -s "$BUN_INSTALL/_bun" ]]; then
  source "$BUN_INSTALL/_bun"
fi

unfunction path_add 2>/dev/null
