for secret_file in \
  "$ZSH_DOTFILES_PATH/secrets/_shared.zsh" \
  "$ZSH_DOTFILES_PATH/secrets/ai.zsh" \
  "$ZSH_DOTFILES_PATH/secrets/dns.zsh" \
  "$ZSH_DOTFILES_PATH/secrets/work.zsh"
do
  [[ -r "$secret_file" ]] && source "$secret_file"
done

unset secret_file

load_all_keys() {
  typeset -f load_ai_keys >/dev/null 2>&1 && load_ai_keys
  typeset -f load_dns_keys >/dev/null 2>&1 && load_dns_keys
  typeset -f load_work_keys >/dev/null 2>&1 && load_work_keys
  typeset -f load_oke_vars >/dev/null 2>&1 && load_oke_vars
}
