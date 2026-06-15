load_ai_keys() {
  __export_secret DEEPSEEK_API_KEY "$DOTFILES_KEY_DIR/deepseek"
  __export_secret CLAUDE_API_KEY "$DOTFILES_KEY_DIR/claude"
  __export_secret GEMINI_API_KEY "$DOTFILES_KEY_DIR/gemini"
  __export_secret TAVILY_API_KEY "$DOTFILES_KEY_DIR/tavily"
  __export_secret GIT_TOKEN "$DOTFILES_KEY_DIR/hrllk-git-token"
}

export OLLAMA_HOST=0.0.0.0
