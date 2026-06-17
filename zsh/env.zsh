export MAVEN_HOME=/opt/homebrew/Cellar/maven/3.9.9/libexec
export GRADLE_HOME=$HOME/task/tmp/gradle-8.10.2
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export IMAGEMAGICK_HOME=/opt/homebrew/var/homebrew/linked/imagemagick
export DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/var/homebrew/linked/imagemagick/lib
export LANG='en_US.UTF-8'
export LC_ALL=en_US.UTF-8

typeset -gU path
path=(
  /opt/homebrew/bin
  /opt/homebrew/lib/ruby/gems/3.4.0/bin
  $JAVA_HOME/bin
  /Applications/IntelliJ\ IDEA.app/Contents/MacOS
  $IMAGEMAGICK_HOME/bin
  /opt/homebrew/opt/kafka/bin
  $HOME/.rd/bin
  /usr/local/texlive/2025/bin/universal-darwin
  $HOME/.local/bin
  $HOME/.bun/bin
  $HOME/.antigravity/antigravity/bin
  /usr/local/bin
  $path
)

export PATH

export EDITOR="nvim"
