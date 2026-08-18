__export_secret DISCORD_USER_ID_ALZAR \
  "$DOTFILES_KEY_DIR/personal/discord/discord-user-id-alzar"
__export_secret DISCORD_BOT_TOKEN_GRAPHKEEPER \
  "$DOTFILES_KEY_DIR/personal/discord/discord-bot-token-graphkeeper"
__export_secret DISCORD_BOT_TOKEN_DEFAULT \
  "$DOTFILES_KEY_DIR/personal/discord/discord-bot-token-default"

if [[ -x "$HOME/.hermes/scripts/sync-secrets" ]]; then
  "$HOME/.hermes/scripts/sync-secrets"
fi
