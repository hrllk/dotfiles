### pre-requires 
- oh-my-zsh
- zsh plugins(hightlight, autosuggestions)



### 1. install plugins (optional?)
#### 1-1. hightlight 
``` zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### 1-2. autosuggestions 
``` zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```



### 2. backup 
``` zsh
mv ~/.zshrc ~/.zshrc.bak
```

### 3. clone 
``` zsh
git clone  https://github.com/hrllk/dotfiles.git ~/dotfiles
````


### 4. link 
```zsh
ln -s ~/dotfiles/.zshrc ~/.zshrc
```

