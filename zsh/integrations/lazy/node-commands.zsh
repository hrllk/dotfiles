__run_with_nvm() {
  local cmd="$1"
  shift

  if ! __load_nvm >/dev/null 2>&1; then
    return 127
  fi

  if ! command -v "$cmd" >/dev/null 2>&1; then
    nvm use --silent default >/dev/null 2>&1 || nvm use --silent node >/dev/null 2>&1 || return 127
  fi

  command "$cmd" "$@"
}

node() { unset -f node; __run_with_nvm node "$@"; }
npm() { unset -f npm; __run_with_nvm npm "$@"; }
npx() { unset -f npx; __run_with_nvm npx "$@"; }
gemini() { unset -f gemini; __run_with_nvm gemini "$@"; }
task-master() { unset -f task-master; __run_with_nvm task-master "$@"; }
openclaw() { unset -f openclaw; __run_with_nvm openclaw "$@"; }
