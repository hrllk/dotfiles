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



### install colorls (using homebrew)

##### pr-requires 
gem (ruby) 

please udpate ruby version using rbenv 
``` bash 
brew insatll rbev
```





#### install font (for colorls icon)
##### 1. tap
``` bash
brew tap homebrew/cask-fonts 
```
##### 2. install 

``` bash
brew install font-hack-nerd-font
```




