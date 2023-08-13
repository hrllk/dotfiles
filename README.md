## install .zsh plugin 

### 0. change sh from bash to zsh optional

install zsh (using pkg manager (apt... )
```
sudo apt install zsh
```

isntall oh zsh (using wget)

it changed to default shell automatically 
```
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```


### install plugins 

#### 1. hightlight 
``` bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### 2. autosuggestions 
``` install & apply auto suggestions 
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

