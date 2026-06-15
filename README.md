### structure
```text
zsh/
  .zshrc
  completion.zsh
  plugins/
    index.zsh
    custom/
      safe-paste.zsh
    omz/
      autosuggestions.zsh
      fzf-tab.zsh
      syntax-highlighting.zsh
  prompt.zsh
  lazy-nvm.zsh
  lazy-node-commands.zsh
  lazy-sdkman.zsh
  local-integrations.zsh
  keybindings.zsh
  paths.zsh
  aliases/
    personal.zsh
    work.zsh
  secrets/
    personal.zsh
    work.zsh
util/
  kitty/
    kitty.conf
  tmux/
    .gitmux.conf
    .tmux.conf
    .tmux/
```

### bootstrap
```zsh
git clone https://github.com/hrllk/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/bootstrap.sh
```

The bootstrap script handles:
- cloning `powerlevel10k`, `fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- backing up existing shell and terminal config files
- creating symlinks for `zsh`, `tmux`, `gitmux`, and `kitty`

`~/.zshrc` should ultimately resolve to `~/dotfiles/zsh/.zshrc`.
If you still have an older link to `~/dotfiles/.zshrc`, rerun bootstrap to refresh it.

### shell startup
```zsh
time zsh -i -c exit
```

The shell setup is structured to keep interactive startup light:
- `~/.zshrc` stays thin and simply resolves into the repository-managed config
- optional integrations are sourced conditionally
- plugin loading is split between local Zsh config and external oh-my-zsh plugins
