export MAVEN_HOME=/opt/homebrew/Cellar/maven/3.9.9/libexec
export GRADLE_HOME=$HOME/task/tmp/gradle-8.10.2
export IMAGEMAGICK_HOME=/opt/homebrew/var/homebrew/linked/imagemagick
export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/var/homebrew/linked/imagemagick/lib
export LANG='en_US.UTF-8'
export LC_ALL=en_US.UTF-8
export BUN_INSTALL="$HOME/.bun"

if [[ -x "$HOME/.sdkman/candidates/java/current/bin/java" ]]; then
  export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
else
  local_java_home="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  if [[ -n "$local_java_home" ]]; then
    export JAVA_HOME="$local_java_home"
  fi
fi

typeset -gU path
path=(
  # /opt/homebrew/opt/git/bin
  /opt/homebrew/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  /opt/homebrew/opt/ruby/bin
  /opt/homebrew/lib/ruby/gems/4.0.0/bin
)

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
  $path
)

export PATH

if [[ -s "$BUN_INSTALL/_bun" ]]; then
  source "$BUN_INSTALL/_bun"
fi

export EDITOR="nvim"
