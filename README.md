### pre-requires
- zsh
- fzf
- zsh plugins(powerlevel10k, fzf-tab, autosuggestions, syntax-highlighting)

### structure
```text
zsh/
  .zshrc
  completion.zsh
  plugins.zsh
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
    .tmux.conf
    .tmux/
```

### 1. install plugins
#### 1-1. powerlevel10k
```zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
```

#### 1-2. fzf-tab
```zsh
git clone https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
```

#### 1-3. highlight
```zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### 1-4. autosuggestions
```zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

### 2. backup
```zsh
mv ~/.zshrc ~/.zshrc.bak
```

### 3. clone
```zsh
git clone https://github.com/hrllk/dotfiles.git ~/dotfiles
```

### 4. link
```zsh
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/dotfiles/util/tmux/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/util/tmux/.tmux ~/.tmux
ln -s ~/dotfiles/util/kitty/kitty.conf ~/.config/kitty/kitty.conf
```
