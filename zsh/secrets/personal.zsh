# AI KEY
__DOTFILES_KEY_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/task/keys"

__export_secret() {
  local name="$1"
  local path="$2"
  local value

  if [[ ! -r "$path" ]]; then
    echo "secret file not readable: $path" >&2
    return 1
  fi

  IFS= read -r value < "$path"
  export "$name=$value"
}

load_ai_keys() {
  __export_secret DEEPSEEK_API_KEY "$__DOTFILES_KEY_DIR/deepseek"
  __export_secret CLAUDE_API_KEY "$__DOTFILES_KEY_DIR/claude"
  __export_secret GEMINI_API_KEY "$__DOTFILES_KEY_DIR/gemini"
  __export_secret TAVILY_API_KEY "$__DOTFILES_KEY_DIR/tavily"
  __export_secret GIT_TOKEN "$__DOTFILES_KEY_DIR/hrllk-git-token"
}

export OLLAMA_HOST=0.0.0.0


# DNS TOKEN
load_dns_keys() {
  __export_secret CLOUD_FLARE_TOKEN "$__DOTFILES_KEY_DIR/dns/cloud-flare-token"
  __export_secret CLOUD_FLARE_ZONEID "$__DOTFILES_KEY_DIR/dns/cloud-flare-token-zoneId"
}

export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

# WORK
load_work_keys() {
  __export_secret FIGMA_TOKEN "$__DOTFILES_KEY_DIR/figma-token"
  __export_secret CONFLUENCE_TOKEN "$__DOTFILES_KEY_DIR/work/confluence"
}

load_all_keys() {
  load_ai_keys
  load_dns_keys
  load_work_keys
  if typeset -f load_oke_vars >/dev/null 2>&1; then
    load_oke_vars
  fi
}
