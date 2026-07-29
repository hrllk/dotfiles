# Tutorial: 새 macOS에서 개발환경 시작하기

이 튜토리얼에서는 새 Mac에 dotfiles를 설치하고, zsh completion과 tmux 설정이 실제로 동작하는 상태까지 만듭니다.

## What you'll need

- macOS와 사용자 홈 디렉터리
- Git과 Homebrew
- 설치할 때 사용할 인터넷 연결

## Step 1: 저장소와 기본 도구 설치

```zsh
brew install fzf neovim tmux
git clone https://github.com/hrllk/dotfiles.git ~/dotfiles
```

이제 설정 원본은 `~/dotfiles`에 있고, fzf-tab completion에 필요한 `fzf`도 준비되었습니다.

## Step 2: Bootstrap 실행

```zsh
bash ~/dotfiles/scripts/bootstrap.sh
```

Bootstrap은 기존 설정을 timestamp backup으로 보존한 뒤 다음 파일을 연결합니다.

```text
~/.zshrc       -> ~/dotfiles/zsh/.zshrc
~/.tmux.conf   -> ~/dotfiles/util/tmux/.tmux.conf
~/.wezterm.lua -> ~/dotfiles/util/wezterm/wezterm.lua
```

## Step 3: 첫 결과 확인

새 셸을 시작하고 completion을 확인합니다.

```zsh
exec zsh
cd ~/dotfiles/
```

여기서 Tab을 누르면 디렉터리 후보가 표시됩니다. `fzf-tab`이 활성화된 환경에서는 `/`를 입력한 뒤 다음 경로 후보로 이어서 이동할 수 있습니다.

## Step 4: tmux 준비

```zsh
tmux new -s work
```

tmux 안에서 `prefix + I`를 눌러 TPM plugin을 설치합니다. 설정을 다시 읽으려면 `prefix + r`를 사용합니다.

## Step 5: Codex와 연결 확인

Codex 설정이 저장소의 `ai/.codex`를 사용하려면 다음 symlink를 확인합니다.

```zsh
ls -ld ~/.codex
```

tmux window에서 Codex 작업이 끝나면 대상 window가 unread 상태로 표시되고, 해당 window를 선택하면 상태가 지워집니다. 이 동작의 세부 조건은 [tmux unread 설계](design-codex-tmux-unread.md)에 있습니다.

## What you built

이제 셸 설정은 저장소에서 버전 관리되고, 홈 디렉터리에는 symlink만 남습니다. plugin과 선택 도구가 없어도 기본 셸 completion은 유지되며, `fzf`, Powerlevel10k, tmux plugin을 추가하면 저장소가 정의한 향상된 환경이 활성화됩니다.

다음으로 [프로젝트 구조 Reference](project-structure.md)에서 새 alias나 plugin 설정을 추가할 위치를 확인할 수 있습니다.

