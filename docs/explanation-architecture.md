# Configuration architecture

이 저장소는 하나의 거대한 `.zshrc`를 유지하는 대신, 빠른 진입점과 기능별 모듈을 분리합니다. 목적은 셸 시작 시간을 줄이고, 한 기능의 변경이 다른 기능의 초기화를 깨뜨리지 않게 하는 것입니다.

## Initialization flow

```text
~/.zshrc
  -> ~/dotfiles/zsh/.zshrc
       -> taskmaster alias
       -> completion + compinit
       -> environment
       -> lazy loaders
       -> secrets index
       -> alias index
       -> plugin index
       -> keybindings
       -> Powerlevel10k theme
       -> reload hook
```

`~/.zshrc`는 저장소 파일을 가리키는 진입점입니다. 실제 조합 순서는 `zsh/.zshrc`에 있고, `source_if_exists`가 선택적 파일의 존재 여부를 확인합니다.

## Why the task-master alias loads early

Powerlevel10k instant prompt가 초기화되는 동안 사용자가 입력할 수 있으므로, `tm` alias를 느린 completion과 plugin 초기화 전에 로드합니다. alias target인 `task-master`는 `node-commands.zsh`의 wrapper function을 통과합니다.

wrapper는 system PATH의 실행 파일을 먼저 사용합니다. PATH에 실행 파일이 없을 때만 nvm을 lazy-load하고 Node 버전을 선택합니다. 이 순서가 없으면 nvm이 설치되지 않은 컴퓨터에서 Homebrew로 설치한 `task-master`도 실행되지 않습니다.

## Optional dependencies are guarded

plugin 설정은 외부 도구가 없어도 기본 기능이 유지되도록 구성합니다.

```text
fzf 설치됨
  -> fzf-tab plugin + continuous-trigger('/') 활성화

fzf 없음
  -> fzf-tab 생략
  -> 기본 zsh completion 유지
```

같은 원칙이 `colorls`, `eza`, `nvm`, `sdkman`, `sshpass`에도 적용됩니다. 기능이 있으면 향상된 경로를 사용하고, 없으면 명시적인 fallback이나 오류 메시지를 제공합니다.

## Module ownership

| 모듈 | 소유 책임 | 의도적으로 하지 않는 일 |
|---|---|---|
| `options/` | 셸 옵션, completion, keybinding | alias나 secret 로드 |
| `env.zsh` | PATH와 공통 환경변수 | 실행 명령 wrapper |
| `integrations/lazy/` | 필요 시 외부 도구 초기화 | 모든 도구를 startup에서 강제 로드 |
| `aliases/` | 짧은 명령과 업무 함수 | plugin 초기화 |
| `plugins/` | OMZ/custom plugin과 theme | 비밀값 설정 |
| `secrets/` | 도메인별 secret export | 값 자체를 저장소에 커밋 |
| `util/` | 터미널·tmux·에디터 설정 | zsh startup 조합 |

이 경계를 지키면 새 alias는 `aliases/`, 새 plugin 설정은 `plugins/omz/`, 새 환경변수는 `env.zsh`에 추가할 수 있습니다.

## Symlink deployment

Bootstrap은 기존 파일을 삭제하지 않습니다. 대상이 이미 존재하면 timestamp backup으로 이동한 뒤 symlink를 생성합니다.

```text
기존 ~/.zshrc
  -> ~/.zshrc.bak.YYYYMMDD-HHMMSS
  -> ~/.zshrc -> ~/dotfiles/zsh/.zshrc
```

이 방식은 재설치 시 복구 경로를 남기지만, bootstrap이 machine-specific 설정을 자동 병합하지는 않습니다. 개인 설정은 저장소 파일에 직접 섞기보다 별도 local override 모듈로 분리하는 편이 안전합니다.

## Codex and tmux integration

Codex hook은 tmux 밖에서는 즉시 종료하고, tmux 안에서는 Codex가 실행된 window의 `@codex_unread` user option을 갱신합니다. tmux format은 이 값을 읽어 window 상태를 표시하고, window 선택 또는 client focus 이벤트가 해당 값을 지웁니다.

상태와 표시를 분리한 이유는 기존 `window-status-style`을 덮어쓰지 않고 읽음 상태만 추가하기 위해서입니다. 자세한 상태 전이는 [tmux unread 설계](design-codex-tmux-unread.md)를 참조합니다.

## Trade-offs

- 빠른 startup을 위해 일부 외부 도구는 첫 호출 시 초기화됩니다. 첫 `nvm`, `sdk`, 또는 Node 명령이 느릴 수 있습니다.
- 여러 파일로 나눠져 있어 새 설정을 찾으려면 `index.zsh`와 `.zshrc`의 source 순서를 알아야 합니다.
- 현재 경로와 Java 경로는 macOS/Homebrew/SDKMAN 환경에 맞춰져 있어 완전한 이식성을 목표로 하지 않습니다.
- secrets는 파일을 분리하지만, 해당 파일은 여전히 로컬 환경에서 안전하게 관리해야 합니다.

