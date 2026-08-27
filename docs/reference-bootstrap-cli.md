# Bootstrap CLI reference

설치와 배포에 사용하는 세 스크립트의 인터페이스를 정리합니다. 설치 절차 자체는 [Bootstrap How-to](howto-bootstrap.md), 처음 설치는 [Tutorial](tutorial-first-setup.md)을 사용합니다.

| 스크립트 | 역할 |
|---|---|
| [`scripts/bootstrap.sh`](../scripts/bootstrap.sh) | 단계 dispatcher. shell/terminal 또는 AI 설정 배포 |
| [`ai/.claude/scripts/link-claude-home`](../ai/.claude/scripts/link-claude-home) | `~/.claude` 연결과 기존 디렉터리 병합 |
| [`ai/.hermes/scripts/sync-secrets`](../ai/.hermes/scripts/sync-secrets) | Hermes launchd 환경 파일 생성 |

---

## `scripts/bootstrap.sh`

```text
usage: bootstrap.sh [--shell-only] [--dry-run] [--ai [--sync-secrets]]
```

### Flags

| Flag | 역할 |
|---|---|
| 인자 없음 | `--shell-only`과 동일 |
| `--shell-only` | plugin clone, backup, shell/terminal symlink |
| `--ai` | Claude/Hermes 연결과 Codex 안내 출력 |
| `--sync-secrets` | Hermes runtime secret 동기화. `--ai` 필요 |
| `--dry-run` | 계획만 출력. network, filesystem, launchctl, secret write 없음 |
| `--help`, `-h` | usage 출력 후 exit `0` |

같은 flag를 두 번 지정하면 `invalid arguments`로 exit `2`입니다.

### 유효하지 않은 조합

| 조합 | 결과 |
|---|---|
| `--ai --shell-only` | exit `2`. `--ai cannot be combined with --shell-only` |
| `--sync-secrets` (단독) | exit `2`. `--sync-secrets requires --ai` |
| 알 수 없는 flag | exit `2`. `invalid arguments: <flag>` |

조합 검증은 어떤 stage보다 먼저 실행되므로, 잘못된 조합은 파일을 전혀 변경하지 않습니다.

### Exit codes

| 코드 | 의미 |
|---|---|
| `0` | 성공 |
| `2` | 인자 또는 조합 오류, 잘못된 `BACKUP_TIMESTAMP` 형식 |
| `10` | preflight 실패. 필수 디렉터리나 명령 누락 |
| `20` | clone 또는 symlink 실패 |
| `30` | secret sync 실패 |

### Environment variables

| 변수 | 기본값 | 역할 |
|---|---|---|
| `DOTFILES_DIR` | `$HOME/dotfiles` | source 저장소 위치 |
| `ZSH_CUSTOM_DIR` | `$HOME/.oh-my-zsh/custom` | zsh plugin 설치 위치 |
| `BACKUP_ROOT` | `$HOME/.dotfiles-backup` | backup 루트로 의도된 경로 |
| `BACKUP_TIMESTAMP` | 실행 시각 | `YYYYMMDD-HHMMSS`. 형식이 맞지 않으면 exit `2` |

`BACKUP_TIMESTAMP`는 invocation 하나에서 모든 backup이 공유합니다. 직접 지정하면 재현 가능한 backup 이름을 만들 수 있습니다.

### Preflight

선택한 stage에 필요한 항목만 검사합니다.

| Stage | 검사 대상 |
|---|---|
| shell | `$DOTFILES_DIR/zsh` 디렉터리, `git`, `ln`, `mv`, `mkdir` |
| AI | `ai/.claude`와 `ai/.hermes` 디렉터리, `ln`, `mv`, `mkdir`, `rsync` |
| sync | `ai/.hermes/scripts/sync-secrets`가 실행 가능 |

### shell/terminal stage

TPM과 zsh plugin을 clone합니다. `<target>/.git`이 이미 있으면 건너뜁니다.

| Repository | 대상 | Depth |
|---|---|---|
| `romkatv/powerlevel10k` | `$ZSH_CUSTOM_DIR/themes/powerlevel10k` | `1` |
| `Aloxaf/fzf-tab` | `$ZSH_CUSTOM_DIR/plugins/fzf-tab` | 전체 |
| `zsh-users/zsh-autosuggestions` | `$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions` | 전체 |
| `zsh-users/zsh-syntax-highlighting` | `$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting` | 전체 |
| `tmux-plugins/tpm` | `$HOME/.local/share/tmux/plugins/tpm` | 전체 |

그 다음 symlink를 만듭니다.

| Link | Source |
|---|---|
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.ideavimrc` | `util/jetbrains/.ideavimrc` |
| `~/.tmux.conf` | `util/tmux/.tmux.conf` |
| `~/.gitmux.conf` | `util/tmux/.gitmux.conf` |
| `~/.tmux` | `util/tmux/.tmux` |
| `~/.config/kitty/kitty.conf` | `util/kitty/kitty.conf` |
| `~/.wezterm.lua` | `util/wezterm/wezterm.lua` |

`link_path`의 판단 순서:

```text
이미 같은 source를 가리키는 symlink  -> 아무것도 하지 않음
다른 symlink이거나 실제 파일         -> backup으로 이동한 뒤 symlink 생성
아무것도 없음                        -> 부모 디렉터리 생성 후 symlink 생성
```

기존 파일을 삭제하지 않으므로 여러 번 실행해도 안전합니다.

### Backup 경로

`link_path`가 기존 대상을 발견하면 `backup_with_timestamp`로 이동합니다. 현재 구현의 실제 동작은 다음과 같습니다.

```text
첫 backup           -> $HOME/<name>.bak.<timestamp>
이름이 이미 있을 때 -> $BACKUP_ROOT/<name>.bak.<timestamp>.<n>
```

즉 **일반적인 경우 backup은 `$BACKUP_ROOT`가 아니라 홈 디렉터리에 생성됩니다.** 완료 메시지는 `backups: $BACKUP_ROOT`를 출력하므로 표시된 경로와 실제 위치가 다릅니다. `~/.claude`를 다루는 `link-claude-home`은 같은 이름의 함수를 다르게 구현해 항상 `$BACKUP_ROOT`에 씁니다.

backup을 찾을 때는 두 위치를 모두 확인합니다.

```zsh
ls -d ~/*.bak.* 2>/dev/null
ls -A "${BACKUP_ROOT:-$HOME/.dotfiles-backup}"
```

이 불일치는 알려진 문제입니다. [구조 검토](review-structural-2026-08-26.md)의 S-04 항목을 참고합니다.

### AI stage

1. `link-claude-home`을 실행합니다. `--dry-run`이면 `--dry-run`, 아니면 `--yes`를 전달하므로 **확인 프롬프트 없이 진행됩니다.**
2. `~/.hermes` -> `ai/.hermes` symlink를 만듭니다.
3. Codex 안내 문장을 출력합니다. 파일 복사나 symlink는 하지 않습니다.

Codex는 의도적으로 자동 배포하지 않습니다. local profile이 필요하면 `ai/.codex/init-home-codex`를 명시적으로 실행합니다.

### 사용 예

```zsh
# 기본 shell/terminal 설치
bash ~/dotfiles/scripts/bootstrap.sh

# 계획만 확인
bash ~/dotfiles/scripts/bootstrap.sh --dry-run --shell-only

# AI 설정 연결
bash ~/dotfiles/scripts/bootstrap.sh --ai

# AI 설정과 Hermes secret 동기화까지
bash ~/dotfiles/scripts/bootstrap.sh --ai --sync-secrets

# 재현 가능한 backup 이름으로 실행
BACKUP_TIMESTAMP=20260826-120000 BACKUP_ROOT="$HOME/.dotfiles-backup" \
  bash ~/dotfiles/scripts/bootstrap.sh --shell-only

# 다른 위치의 저장소를 대상으로 실행
DOTFILES_DIR="$HOME/work/dotfiles" \
  bash "$HOME/work/dotfiles/scripts/bootstrap.sh"
```

---

## `ai/.claude/scripts/link-claude-home`

```text
usage: link-claude-home [--dry-run] [--yes]
```

`~/.claude`를 저장소의 `ai/.claude`로 연결합니다. `bootstrap.sh --ai`가 내부적으로 호출하지만 직접 실행할 수도 있습니다.

| Flag | 역할 |
|---|---|
| `--dry-run` | 계획만 출력. 확인 프롬프트도 건너뜀 |
| `--yes`, `-y` | 실제 디렉터리 이전 시 확인 프롬프트 생략 |
| `--help`, `-h` | usage 출력 후 exit `0` |

| 변수 | 기본값 |
|---|---|
| `DOTFILES_DIR` | `$HOME/dotfiles` |
| `CLAUDE_HOME` | `$HOME/.claude` |
| `BACKUP_ROOT` | `$HOME/.dotfiles-backup` |
| `BACKUP_TIMESTAMP` | 실행 시각 |

대상 상태별 동작:

| `~/.claude` 상태 | 동작 |
|---|---|
| 이미 `ai/.claude`를 가리키는 symlink | `already linked` 출력 후 exit `0` |
| 다른 곳을 가리키는 symlink | backup으로 이동한 뒤 재연결 |
| 실제 디렉터리 | 내용을 저장소로 병합, 원본을 backup으로 이동, symlink 생성 |
| 디렉터리가 아닌 파일 | 오류 후 exit `1` |
| 없음 | 바로 symlink 생성 |

실제 디렉터리를 이전할 때는 `rsync -a --ignore-existing`을 사용합니다. `--ignore-existing`이므로 **저장소에 이미 있는 파일이 우선**하고, 홈에만 있던 runtime 파일이 저장소 디렉터리로 들어옵니다. 이 파일들은 `ai/.claude/.gitignore`의 allowlist가 걸러내므로 대부분 추적되지 않습니다.

`claude` 프로세스가 실행 중이면 경고하고 계속할지 확인합니다. `--yes` 또는 `--dry-run`이면 확인 없이 진행합니다.

실행 후 whitelist가 무엇을 노출하는지 직접 확인하라는 안내를 출력합니다.

```zsh
git -C ~/dotfiles status --short ai/.claude
```

---

## `ai/.hermes/scripts/sync-secrets`

인자를 받지 않습니다. Discord secret 파일을 읽어 Hermes launchd가 사용하는 환경 파일을 생성합니다.

| 변수 | 기본값 | 역할 |
|---|---|---|
| `DOTFILES_KEY_DIR` | iCloud `task/keys` | secret 파일 루트 |
| `HERMES_LAUNCHD_ENV` | `$HOME/.hermes/.launchd.env` | 출력 파일 |

입력으로 사용하는 glob:

```text
$DOTFILES_KEY_DIR/personal/discord/discord-bot-token-*
$DOTFILES_KEY_DIR/personal/discord/discord-user-id-*
```

파일 이름을 환경변수 이름으로 변환합니다.

```text
discord-bot-token-graphkeeper  ->  DISCORD_BOT_TOKEN_GRAPHKEEPER
discord-user-id-alzar          ->  DISCORD_USER_ID_ALZAR
```

출력은 `umask 077`과 `chmod 600`을 적용한 임시 파일에 쓴 뒤 atomic하게 교체합니다. 쓰기 전에 두 변수가 있는지 검증합니다.

| 검증 | 실패 시 |
|---|---|
| glob 결과가 하나 이상 | `No Hermes Discord secret files found`, exit `1` |
| 각 파일이 읽기 가능 | `Hermes secret file is not readable`, exit `1` |
| 각 값이 비어 있지 않음 | `Hermes secret file is empty`, exit `1` |
| `DISCORD_USER_ID_ALZAR` 존재 | `grep` 실패로 종료 |
| `DISCORD_BOT_TOKEN_DEFAULT` 존재 | `grep` 실패로 종료 |

성공하면 `Hermes secrets synced`를 출력합니다. secret 값 자체는 출력하지 않습니다.

---

## Related

- [Bootstrap How-to](howto-bootstrap.md): 재실행, 검증, 문제 해결 절차
- [How to add configuration](howto-add-configuration.md): 새 모듈이나 profile을 추가하는 절차
- [Hermes gateway reference](reference-hermes-gateways.md): gateway 스크립트와 launchd 연동
- [Secret handling](explanation-secret-handling.md): key 파일에서 gateway까지의 흐름
- [구조 검토](review-structural-2026-08-26.md): backup 경로 불일치를 포함한 알려진 문제
