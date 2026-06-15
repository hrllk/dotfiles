alias todo='cd $HOME/task/sources/personal/secretary && nvim'
alias cdsource='cd $HOME/task/sources'
alias cdtask='cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs/task"'

if command -v colorls >/dev/null 2>&1; then
  alias ll='colorls -lGt --gs --sd'
  alias ls='colorls'
else
  alias ll='ls -lG'
fi

tree() {
  local depth=1
  local mode="all"

  [[ -n "$1" ]] && depth=$1
  [[ -n "$2" ]] && mode=$2

  if command -v colorls >/dev/null 2>&1; then
    if [[ "$mode" == "dirs" ]]; then
      colorls "${dir:-.}" -l --tree="${depth}" --dirs
    else
      colorls "${dir:-.}" -l --tree="${depth}" --sd --sf
    fi
  else
    command tree -L "$depth" "${dir:-.}"
  fi
}
