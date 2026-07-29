# Project structure reference

이 문서는 저장소의 파일 배치와 각 영역의 공개 역할을 설명합니다. 실제 설정의 진입점은 [README.md](../README.md)와 `zsh/.zshrc`입니다.

## Top-level layout

```text
.
├── archive/              이전 설정과 역사적 자료
├── ai/.codex/            Codex harness, hooks, skills, 작업 문서
├── docs/                 저장소 설계·테스트·운영 문서
├── scripts/              저장소 bootstrap 진입점
├── util/                 터미널·tmux·에디터 설정과 이미지 자산
├── zsh/                  실제 zsh 설정
├── README.md             설치와 개요
└── package.json          Yarn 프로젝트 메타데이터
```

`archive/`는 활성 설정 경로가 아닙니다. `ai/.codex/`는 `~/.codex` symlink를 통해 Codex 설정으로 사용되는 별도 harness 영역입니다.

## Bootstrap surface

[`scripts/bootstrap.sh`](../scripts/bootstrap.sh)는 다음 작업을 수행합니다.

| 영역 | 동작 | 기본 대상 |
|---|---|---|
| 외부 plugin | 없을 때 Git clone | `~/.oh-my-zsh/custom/`, `~/.local/share/tmux/plugins/tpm` |
| 백업 | 기존 파일·symlink를 timestamp backup으로 이동 | `~/.dotfiles-backup/` 또는 홈 디렉터리의 `.bak.*` |
| zsh | 저장소 설정 연결 | `~/.zshrc` |
| tmux | 설정과 plugin 디렉터리 연결 | `~/.tmux.conf`, `~/.gitmux.conf`, `~/.tmux` |
| terminal | Kitty와 WezTerm 설정 연결 | `~/.config/kitty/kitty.conf`, `~/.wezterm.lua` |
| editor | JetBrains Vim 설정 연결 | `~/.ideavimrc` |

경로는 `DOTFILES_DIR`, `ZSH_CUSTOM_DIR`, `BACKUP_ROOT` 환경변수로 덮어쓸 수 있습니다. [Bootstrap How-to](howto-bootstrap.md)에 실행 예와 검증 절차가 있습니다.

## zsh layout

```text
zsh/.zshrc
├── aliases/taskmaster.zsh       빠른 task-master alias
├── options/completion.zsh       compinit, matcher, menu, zcompdump
├── env.zsh                      PATH와 공통 환경변수
├── integrations/lazy/            nvm, Node 명령, SDKMAN lazy loader
├── secrets/index.zsh             도메인별 비밀값 로더
├── aliases/index.zsh             navigation, git, tools, work alias 조합
├── plugins/index.zsh             custom/OMZ 개별 설정 조합
├── options/keybindings.zsh       vi mode와 키 바인딩
└── plugins/omz/theme.zsh         Powerlevel10k와 prompt 설정
```

각 파일은 존재할 때만 source됩니다. 따라서 선택적 plugin이나 machine-specific secret 파일이 없어도 전체 셸 초기화가 중단되지 않습니다.

## zsh public surface

### Alias groups

- Navigation: `todo`, `cdsource`, `cdtask`, `ll`, `ls`
- Git: `gs`, `gst`, `ga`, `gaa`, `gb`, `gc`, `gco`, `gcb`, `gcm`, `gca`, `gp`, `gpf`, `gl`, `gm`, `grb`, `gd`, `gds`, `gr`, `grs`, `grh`, `gt`, `gstash`, `gsta`, `gpop`, `gclean`, `glgc`, `glga`
- Tools: `vi`, `k`
- General: `hgrep`, `cl`
- Task Master: `tm`, `taskmaster`, `hamster`, `ham`
- Work: `godcprd`, `godcstg`, `godcdev`

Git alias는 trace 환경변수를 함께 설정합니다. 실행 로그가 필요 없을 때도 alias 정의 자체는 동일하므로, 조용한 Git 명령이 필요하면 `command git ...`을 사용합니다.

### Functions

- `tree [depth] [all|dirs]`: `colorls`, 시스템 `tree`, `ls` 순서로 fallback하는 디렉터리 표시 함수
- `nvm ...`, `sdk ...`: 실제 loader를 처음 사용할 때 초기화하는 lazy wrapper
- `npx ...`, `gemini ...`, `task-master ...`, `openclaw ...`: 사용 가능한 system PATH 명령을 먼저 실행하고, 없으면 nvm을 시도하는 Node wrapper
- `godcprd`, `godcstg`, `godcdev`: OKE 환경변수, known_hosts, `sshpass`를 검사한 뒤 원격 서버에 접속

### Completion and plugins

`options/completion.zsh`는 zsh completion을 초기화합니다. `fzf`가 설치되어 있으면 `plugins/omz/fzf-tab.zsh`가 `fzf-tab`을 활성화하고 `/` 연속 경로 completion을 제공합니다. `fzf`가 없으면 기본 zsh completion으로 fallback합니다.

## Terminal and tmux

- `util/kitty/kitty.conf`: Kitty 폰트, 색상, 알림, shell 실행 설정
- `util/wezterm/wezterm.lua`: WezTerm 폰트, 배경 이미지, 창·탭·키 바인딩 설정
- `util/tmux/.tmux.conf`: tmux plugin, 상태바, pane, copy mode, window 상태 설정
- `util/tmux/.gitmux.conf`: tmux 상태바에 Git 상태를 표시하는 gitmux 설정
- `util/tmux/.tmux/scripts/mem_real_macos.sh`: macOS 메모리 사용량 표시 스크립트

Codex Stop hook은 `ai/.codex/hooks.json`에서 [`ai/.codex/tmux-notify-hook.sh`](../ai/.codex/tmux-notify-hook.sh)를 호출합니다. `~/.codex -> ai/.codex` symlink가 있어야 활성 설정이 저장소와 일치합니다.

## Files not used as active configuration

- `archive/`: 이전 설정 보관
- `README.md.bak`: README 이전 백업
- `util/assets/wallpapers/`: WezTerm 등에서 참조할 수 있는 정적 이미지

