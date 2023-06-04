# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/hr.k/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git)
plugins=(
	git
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh


## ENV Variables 
export JKS_HOME=~/task/jks
export ADB_HOME=/Users/hr.k/Library/Android/sdk
export SPRING_HOME=/Users/hr.k/util/spring-2.3.8.RELEASE
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
export HOMEBREW_RABBITMQ=/opt/homebrew/Cellar/rabbitmq/3.10.7
# export RUBY_HOME=~/.gem/ruby/3.0.0
# export RUBY_HOME=/opt/homebrew/lib/ruby/gems/3.0.0
# export RBENV_HOME=~/.rbenv
export KAFKA_HOME=~/util/kafka_2.12-3.0.0
export GEM_HOME=$HOME/.gem/ruby/2.6.0
export RBENV_HOME=$HOME/.rbenv/versions/2.6.10
export LDFLAGS="-L/opt/homebrew/opt/libiconv/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libiconv/include"
export FP_HOME="/Users/hr.k/util/fp"
export MYVIMRC="$HOME/.config/nvim/init.vim"
# export IDEA_HOME="/System/Volumes/Data/Users/hr.k/Library/Application Support/JetBrains/Toolbox/apps/IDEA-U/ch-0/213.5744.223/IntelliJ IDEA.app/Contents/MacOS"
export IDEA_HOME="/Applications/IntelliJ IDEA.app/Contents/MacOS"
export AND_STUDIO_HOME="/Applications/IntelliJ IDEA.app/Contents/MacOS"
export JDTLS_HOME=$HOME/.local/share/nvim/lsp/jdt-language-server
export WORKSPACE=$HOME/.local/share/nvim/lsp/jdt-language-server/workspace


export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH=$PATH:$GEM_HOME/bin
export PATH=$PATH:$SPRING_HOME/bin
export PATH=$PATH:$ADB_HOME/platform-tools
export PATH=$PATH:$KAFKA_HOME/bin
export PATH=$PATH:$FP_HOME
export PATH=$PATH:$RBENV_HOME/bin
export PATH=$PATH:$HOMEBREW_RABBITMQ/sbin
export PATH=$PATH:$IDEA_HOME
export PATH=$PATH:$AND_STUDIO_HOME
export PATH=$PATH:$JAVA_HOME/bin
export PATH="$PATH:`yarn global bin`"


eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# rbenv init 적당한 루비버전으로 실행시켜주는 도구 
export LANG='en_US.UTF-8' 
# export LC_ALL=ko_KR.UTF-8
export LC_ALL=en_US.UTF-8
# source $(dirname $(gem which colorls))/tab_complete.sh
# there is colorls at this line. so the alias does not work
# second, the path is worng
eval "$(rbenv init - zsh)"



## shortcut 
source $HOME/.aliases

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi



set -o vi
