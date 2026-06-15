load_dns_keys() {
  __export_secret CLOUD_FLARE_TOKEN "$DOTFILES_KEY_DIR/dns/cloud-flare-token"
  __export_secret CLOUD_FLARE_ZONEID "$DOTFILES_KEY_DIR/dns/cloud-flare-token-zoneId"
}

export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
