# How to bootstrap the dotfiles

이 가이드는 새 macOS 환경에 저장소를 설치하고 설정 symlink를 연결하는 방법을 설명합니다.

## Prerequisites

다음 도구가 필요합니다.

- Git, Bash, zsh
- Homebrew
- oh-my-zsh
- Neovim, tmux
- `fzf` for fzf-tab's interactive completion

선택 도구는 `colorls` 또는 `eza`, `kubectl`, `sshpass`, `nvm`, `sdkman`입니다. Bootstrap은 이 도구들을 설치하지 않고, 외부 plugin 저장소와 TPM만 clone합니다.

## Steps

1. 저장소를 clone합니다.

   ```zsh
   git clone https://github.com/hrllk/dotfiles.git ~/dotfiles
   ```

2. 필수 도구를 준비합니다.

   ```zsh
   brew install fzf neovim tmux
   ```

   oh-my-zsh가 아직 없다면 공식 설치 절차를 먼저 완료합니다.

3. Bootstrap을 실행합니다.

   ```zsh
   bash ~/dotfiles/scripts/bootstrap.sh
   ```

   스크립트는 Powerlevel10k, fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting, TPM을 없을 때만 clone하고, 기존 설정을 backup한 뒤 symlink를 생성합니다.

4. tmux plugin을 설치합니다.

   tmux를 시작한 뒤 `prefix + I`를 누릅니다. TPM plugin은 저장소에 커밋되지 않고 `~/.local/share/tmux/plugins/`에 설치됩니다.

5. 새 셸을 시작합니다.

   ```zsh
   exec zsh
   ```

## Verify

다음 명령으로 주요 symlink와 셸 기능을 확인합니다.

```zsh
ls -l ~/.zshrc ~/.tmux.conf ~/.gitmux.conf ~/.wezterm.lua ~/.ideavimrc
type tm task-master fzf
bindkey -M viins '^I'
time zsh -i -c exit
```

정상 상태에서는 `tm`이 `task-master` alias이고, `^I`가 fzf 설치 시 `fzf-tab-complete`에 연결됩니다. `fzf`가 없으면 `expand-or-complete`가 기본 fallback입니다.

## Re-run safely

설정이 바뀐 뒤 bootstrap을 다시 실행해도 기존 파일을 삭제하지 않습니다. 기존 대상이 다른 파일이나 symlink라면 timestamp backup으로 이동합니다. 백업 위치는 출력되는 `backups:` 경로에서 확인합니다.

환경별 경로를 바꾸려면 다음처럼 실행합니다.

```zsh
DOTFILES_DIR="$HOME/work/dotfiles" \
ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom" \
bash "$HOME/work/dotfiles/scripts/bootstrap.sh"
```

## Troubleshooting

### `tm`이 출력 없이 종료됨

현재 셸을 다시 읽고 command resolution을 확인합니다.

```zsh
source ~/.zshrc
type -a tm task-master
tm --help
```

`task-master`가 system PATH에 있으면 wrapper가 바로 실행합니다. nvm만 사용하는 경우에는 nvm의 default 또는 node alias가 준비되어 있어야 합니다.

### `cd path/` 후 Tab이 다음 경로로 이어지지 않음

`fzf` 설치 여부와 Tab widget을 확인합니다.

```zsh
command -v fzf
bindkey -M viins '^I'
```

`fzf`가 없으면 `brew install fzf` 후 `exec zsh`를 실행합니다. `fzf-tab`은 외부 plugin이므로 bootstrap이 clone한 plugin 디렉터리도 존재해야 합니다.

### secret 관련 오류가 발생함

`zsh/secrets/index.zsh`가 source하는 도메인 파일과 권한을 확인합니다. 값 자체를 저장소 파일이나 문서에 추가하지 말고, 필요한 local secret 파일을 개인 환경에서만 관리합니다.

### 설정이 반영되지 않음

symlink가 저장소를 가리키는지 확인한 뒤 새 셸을 시작합니다.

```zsh
readlink ~/.zshrc
exec zsh
```

