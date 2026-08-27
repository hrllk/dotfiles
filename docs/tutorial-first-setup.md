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
# shell/terminal setup
bash ~/dotfiles/scripts/bootstrap.sh --shell-only

# AI setup, when needed
bash ~/dotfiles/scripts/bootstrap.sh --ai

# Explicitly synchronize Hermes runtime secrets
bash ~/dotfiles/scripts/bootstrap.sh --ai --sync-secrets
```

`--dry-run`을 붙이면 network, backup, symlink, secret write 없이 실행 계획만 확인할 수 있습니다. Codex local profile은 bootstrap이 자동 생성하지 않습니다.

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

## Step 5: Codex local profile 준비

`bootstrap.sh --ai`는 Codex를 복사하거나 링크하지 않고 안내 문장만 출력합니다. 연결과 profile 생성은 명시적으로 실행합니다.

먼저 `~/.codex`를 저장소로 연결합니다.

```zsh
~/dotfiles/ai/.codex/init-home-codex
```

기존 `~/.codex`가 있으면 `~/.codex.bak.<timestamp>`로 옮긴 뒤 symlink를 만듭니다. 이미 같은 곳을 가리키고 있으면 아무 것도 하지 않습니다.

```zsh
ls -ld ~/.codex     # ~/dotfiles/ai/.codex 를 가리켜야 함
```

다음으로 local profile을 만듭니다. 이 파일은 machine-local 설정을 담으므로 저장소가 추적하지 않습니다.

```zsh
cp ~/.codex/local.config.toml.example ~/.codex/local.config.toml
chmod 600 ~/.codex/local.config.toml
```

`codex` 명령은 저장소의 wrapper 함수를 통과합니다. wrapper는 `-p`/`--profile`을 직접 지정하지 않으면 local profile의 존재, 소유자, 권한을 검사한 뒤 `codex -p local`로 실행합니다.

```zsh
codex --version
```

local profile이 없으면 다음 메시지와 함께 종료합니다.

```text
Codex local profile is missing: local.config.toml
Create it from: ~/.codex/local.config.toml.example
```

검사 항목과 종료 코드는 [Shell command reference](reference-shell-commands.md)의 Codex wrapper 절에 있습니다.

tmux window에서 Codex 작업이 끝나면 대상 window가 unread 상태로 표시되고, 해당 window를 선택하면 상태가 지워집니다. 이 동작의 세부 조건은 [tmux unread 설계](design-codex-tmux-unread.md)에 있습니다.

## What you built

이제 셸 설정은 저장소에서 버전 관리되고, 홈 디렉터리에는 symlink만 남습니다. plugin과 선택 도구가 없어도 기본 셸 completion은 유지되며, `fzf`, Powerlevel10k, tmux plugin을 추가하면 저장소가 정의한 향상된 환경이 활성화됩니다.

다음 문서로 이어집니다.

- [Shell command reference](reference-shell-commands.md): 방금 설치한 환경에서 쓸 수 있는 명령 전체
- [프로젝트 구조 Reference](project-structure.md): 새 alias나 plugin 설정을 추가할 위치
- [How to add configuration](howto-add-configuration.md): 설정을 추가하는 구체적 절차

