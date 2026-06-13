### pre-requires
- zsh
- fzf
- zsh plugins(powerlevel10k, fzf-tab, autosuggestions, syntax-highlighting)

### structure
```text
zsh/
  .zshrc
  completion.zsh
  plugins/
    index.zsh
    autosuggestions.zsh
    fzf-tab.zsh
    syntax-highlighting.zsh
  prompt.zsh
  lazy-nvm.zsh
  lazy-node-commands.zsh
  lazy-sdkman.zsh
  local-integrations.zsh
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
