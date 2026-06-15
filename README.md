### structure
```text
zsh/
  .zshrc
  env.zsh
  options/
    completion.zsh
    keybindings.zsh
  integrations/
    lazy/
      nvm.zsh
      node-commands.zsh
      sdkman.zsh
  aliases/
    index.zsh
    navigation.zsh
    git.zsh
    taskmaster.zsh
    tools.zsh
    others.zsh
    work.zsh
  plugins/
    index.zsh
    custom/
      safe-paste.zsh
    omz/
      autosuggestions.zsh
      fzf-tab.zsh
      prompt.zsh
      syntax-highlighting.zsh
  secrets/
    index.zsh
    _shared.zsh
    ai.zsh
    dns.zsh
    work.zsh
util/
  jetbrains/
    .ideavimrc
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
- creating symlinks for `zsh`, `ideavim`, `tmux`, `gitmux`, and `kitty`

`~/.zshrc` should ultimately resolve to `~/dotfiles/zsh/.zshrc`.
If you still have an older link to `~/dotfiles/.zshrc`, rerun bootstrap to refresh it.
`~/.ideavimrc` should resolve to `~/dotfiles/util/jetbrains/.ideavimrc`.

### shell startup
```zsh
time zsh -i -c exit
```

> zsh -i -c exit  0.05s user 0.04s system 61% cpu 0.149 total

The shell setup is structured to keep interactive startup light:
- `~/.zshrc` stays thin and simply resolves into the repository-managed config
- optional integrations are sourced conditionally
- plugin loading is split between local Zsh config and external oh-my-zsh plugins
- secrets are grouped by domain with a shared loader and an index file
