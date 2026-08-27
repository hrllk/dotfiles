# Secret handling

이 저장소는 공개 저장소에 추적되는 파일 안에 `.env`와 secret 참조를 함께 담고 있습니다. 그런데도 토큰이 노출되지 않습니다. 이 문서는 그것을 가능하게 하는 **간접 계층**과 그 대가를 설명합니다.

## The problem

dotfiles는 본질적으로 충돌하는 두 요구를 동시에 만족해야 합니다.

1. 설정은 버전 관리해야 한다. 새 기기에서 재현할 수 있어야 하고, 변경 이력이 남아야 한다.
2. 설정은 credential을 참조한다. Discord bot token, API 키, 데이터센터 root 비밀번호.

두 요구를 소홀히 다루면 흔한 실패로 이어집니다.

```text
전부 커밋한다
  -> 토큰이 git 이력에 영구히 남는다. rotate 외에는 되돌릴 방법이 없다

전부 gitignore한다
  -> 새 기기에서 무엇을 채워야 하는지 알 수 없다
  -> 설정 구조 자체가 버전 관리에서 빠진다

각 기기에서 손으로 export한다
  -> 어떤 변수가 필요한지 아무도 기억하지 못한다
  -> 값과 구조가 조용히 갈라진다
```

이 저장소는 세 번째 길을 택합니다. **구조는 커밋하고, 값은 커밋하지 않고, 둘을 이름으로 연결합니다.**

## The approach

값은 저장소 밖 한 곳에만 존재합니다. 나머지 계층은 모두 이름만 다룹니다.

```text
┌─ iCloud Drive ──────────────────────────────────────┐
│ $DOTFILES_KEY_DIR/                                  │
│   claude, gemini, deepseek, tavily                  │  ← 값이 있는 유일한 곳
│   hrllk-git-token                                   │     파일 하나 = 값 하나
│   dns/cloud-flare-token                             │     저장소 밖
│   work/confluence, work/dc_trb_{prd,stg,dev}        │
│   personal/discord/discord-bot-token-*              │
└──────────────────┬──────────────────────────────────┘
                   │
     ┌─────────────┴─────────────┐
     │                           │
     ▼                           ▼
┌─ 대화형 셸 ─────────┐   ┌─ Hermes launchd ────────────┐
│ zsh/secrets/        │   │ scripts/sync-secrets        │
│  __export_secret    │   │  파일명 -> 변수명 변환      │
│  NAME <- 파일 첫 줄 │   │  .launchd.env (chmod 600)   │
└──────────┬──────────┘   └──────────┬──────────────────┘
           │                         │
           ▼                         ▼
    export NAME=value        bin/gateway-<profile>
    (셸 프로세스에만)         source .launchd.env
                             export DISCORD_BOT_TOKEN=...
                                      │
                                      ▼
                             profiles/<p>/.env
                             DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN_X}
                                      ↑
                             추적되는 파일은 여기까지.
                             참조만 있고 값은 없다.
```

핵심은 마지막 화살표입니다. 추적되는 `.env`는 값 대신 `${VAR}` 참조를 담습니다.

```env
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN_GRAPHKEEPER}
DISCORD_ALLOWED_USERS=${DISCORD_USER_ID_ALZAR}
```

그래서 `ai/.hermes/profiles/*/.env`를 그대로 커밋해도 안전합니다. 파일은 "이 profile은 graphkeeper 토큰을 쓴다"는 **사실**을 기록하고, 그 토큰이 무엇인지는 기록하지 않습니다. 새 기기에서는 같은 구조가 그대로 재현되고, 값만 iCloud에서 채워집니다.

### 왜 iCloud인가

key 디렉터리 기본값은 `~/Library/Mobile Documents/com~apple~CloudDocs/task/keys`입니다.

기기 간 동기화를 파일 시스템에 위임하면 dotfiles가 secret 배포 문제를 풀지 않아도 됩니다. 새 Mac에서 iCloud가 동기화되면 key 파일이 이미 제자리에 있고, bootstrap은 아무 값도 전송하지 않습니다. `DOTFILES_KEY_DIR`로 위치를 바꿀 수 있으므로 iCloud에 묶이지도 않습니다.

대가는 [Trade-offs](#trade-offs)에 정리합니다.

### 셸 쪽: 도메인 분리와 지연 로드

`zsh/secrets/`는 도메인별로 나뉘고 `index.zsh` 하나가 진입점입니다.

| 파일 | loader | 시점 |
|---|---|---|
| `_shared.zsh` | `__export_secret` 정의, `DOTFILES_KEY_DIR` 설정 | startup |
| `ai.zsh` | `load_ai_keys` | 호출 시 |
| `dns.zsh` | `load_dns_keys` | 호출 시 |
| `work.zsh` | `load_work_keys`, `load_oke_vars` | 호출 시 |
| `personal.zsh` | 없음 | **startup에 즉시** |

대부분을 함수로 감싼 이유는 두 가지입니다.

첫째, 셸 시작 시간입니다. `__export_secret`은 파일을 읽습니다. iCloud 경로 읽기는 로컬 디스크보다 느리고, 파일이 아직 내려오지 않았다면 더 느립니다. 시작할 때 12개를 모두 읽으면 프롬프트가 눈에 띄게 늦어집니다.

둘째, 노출 범위입니다. `godcprd`를 실행할 때만 `DC_TRB_PRD`가 환경에 들어옵니다. 데이터센터 비밀번호가 모든 셸, 모든 자식 프로세스의 환경에 상주하지 않습니다. `env` 덤프나 크래시 리포트에 담길 표면이 그만큼 줄어듭니다.

`load_all_keys`는 필요할 때 한 번에 부르는 편의 함수입니다. `typeset -f`로 각 loader의 존재를 확인하고 호출하므로, 도메인 파일이 없는 기기에서도 실패하지 않습니다.

`personal.zsh`만 이 규약에서 벗어납니다. loader 함수 없이 top-level에서 세 값을 즉시 export합니다. Hermes gateway 관련 값이라 항상 필요하다는 판단으로 보이지만, 결과적으로 두 가지 비용을 만듭니다. 셸을 열 때마다 iCloud 파일 3개를 읽고, 파일이 없으면 `secret file not readable`이 세 줄 출력됩니다. `load_all_keys`도 이 파일을 다루지 않아 "모든 키 로드"라는 이름과 실제 범위가 어긋납니다. [구조 검토](review-structural-2026-08-26.md)의 S-07 항목을 참고합니다.

### launchd 쪽: 이름 변환과 atomic write

launchd로 실행되는 gateway는 로그인 셸 환경을 물려받지 않습니다. `zsh/secrets/`가 export한 값에 접근할 수 없습니다. 그래서 별도 경로가 필요합니다.

`sync-secrets`가 key 파일을 읽어 `.launchd.env` 하나로 모읍니다. 변환 규칙은 파일 이름에서 유도합니다.

```text
discord-bot-token-graphkeeper  ->  DISCORD_BOT_TOKEN_GRAPHKEEPER
discord-user-id-alzar          ->  DISCORD_USER_ID_ALZAR
```

이 규칙이 중요한 이유는 **새 profile을 만들 때 배선을 손으로 하지 않아도 된다는 것**입니다. `gateway-management-profile`이 `my-agent`라는 이름을 받으면 key 파일 이름, 환경변수 이름, `.env` 참조, wrapper의 export 문을 모두 같은 규칙으로 유도합니다. 이름 하나가 전체 사슬을 결정하므로 어긋날 여지가 없습니다.

쓰기는 방어적입니다.

| 조치 | 이유 |
|---|---|
| `umask 077` + `chmod 600` | 다른 사용자가 읽지 못하게 |
| `mktemp` 후 `mv -f` | 부분적으로 쓰인 파일이 노출되지 않게 (atomic) |
| `trap 'rm -f "$tmp"' EXIT` | 실패 시 임시 파일을 남기지 않게 |
| 빈 값 검사 | 빈 토큰으로 gateway가 조용히 뜨지 않게 |
| `grep` 사후 검증 | 필수 변수 두 개가 실제로 쓰였는지 확인 |
| `printf '%s' ... \| tr` 로 값 미출력 | 로그에 값이 남지 않게 |

wrapper 쪽에도 게이트가 있습니다.

```zsh
set -eu
[[ -r "$LAUNCHD_ENV" ]]
source "$LAUNCHD_ENV"
export DISCORD_BOT_TOKEN="$DISCORD_BOT_TOKEN_GRAPHKEEPER"
[[ -n "$DISCORD_BOT_TOKEN" && -n "$DISCORD_ALLOWED_USERS" ]]
```

`set -eu`에서 `[[ ]]`가 실패하면 스크립트가 즉시 끝납니다. 토큰 없이 Hermes가 시작해 인증 실패 루프에 빠지는 대신, 아예 실행되지 않고 launchd 로그에 남습니다. **조용한 오작동보다 명확한 실패**를 택한 설계입니다.

### 저장소 쪽: allowlist gitignore

간접 계층만으로는 부족합니다. AI 도구 홈 디렉터리는 설정과 런타임 상태를 같은 트리에 섞어 두고, 그 안에는 credential 캐시도 있습니다. `~/.claude`를 저장소에 연결한다는 것은 **아직 존재하지 않는 파일까지 포함해** 그 트리 전체를 저장소 안에 두는 것입니다.

denylist로는 이길 수 없는 싸움입니다. 도구가 업데이트되면서 새 상태 파일을 만들고, 그중 하나가 토큰을 담고 있으면 조용히 추적됩니다.

그래서 `ai/.claude`, `ai/.codex`, `ai/.hermes`는 방향을 뒤집습니다.

```gitignore
*

!.gitignore
!settings.json
!skills/**/*.md
...
```

기본이 "무시"이고, 추적할 것을 이름으로 지정합니다. 새 파일이 생기면 기본 동작은 **무시**입니다. 실수의 방향이 노출이 아니라 누락이 됩니다.

`ai/.claude/.gitignore`는 그 위에 명시적 거부까지 더합니다.

```gitignore
.credentials.json
*.credentials.json
settings.local.json
```

`*`가 이미 모두 무시하므로 이 줄들은 기능적으로 중복입니다. 의도를 문서화하는 역할이고, 누군가 위쪽 allowlist를 넓혔을 때 최후의 방어선이 됩니다.

`link-claude-home`이 `rsync --ignore-existing`을 쓰는 것도 같은 방향입니다. 기존 홈 디렉터리를 저장소로 병합할 때 저장소 파일이 우선하므로, 로컬 상태가 버전 관리되는 설정을 덮어쓰지 못합니다. 병합된 런타임 파일은 allowlist가 걸러냅니다.

## Trade-offs

이 설계가 실제로 포기한 것들입니다.

**iCloud가 단일 실패 지점이다.** iCloud가 동기화되지 않았거나 파일이 아직 내려오지 않았으면 `__export_secret`이 실패합니다. 오류는 `secret file not readable` 한 줄이고 어느 변수인지 말해주지 않습니다. 실패 메시지에 변수 이름이나 경로가 없는 것은 의도적이지만(로그 노출 방지), 진단은 그만큼 어려워집니다.

**값과 구조가 갈라질 수 있다.** `.env`가 `${DISCORD_BOT_TOKEN_BLOG}`를 참조하는데 대응하는 key 파일이 없으면, 저장소는 완전해 보이지만 gateway는 뜨지 않습니다. `sync-secrets`가 필수 변수 두 개만 검증하므로 나머지는 실행 시점에야 드러납니다.

**지연 로드는 규율을 요구한다.** `godcprd` 같은 함수는 `load_oke_vars`를 직접 불러야 합니다. 새 함수를 추가하면서 이 호출을 잊으면 빈 비밀번호로 조용히 실패합니다.

**allowlist는 새 파일을 조용히 삼킨다.** 안전한 기본값의 대가입니다. `ai/.codex/skills/`에 새 skill을 추가해도 `git status`에 나타나지 않습니다. 이미 추적되던 파일들은 allowlist 도입 전에 추가된 것이라 계속 추적되어, 같은 디렉터리에서 파일마다 동작이 다릅니다. 이것은 실제로 문제를 일으키는 지점입니다. [구조 검토](review-structural-2026-08-26.md)의 S-05 항목을 참고합니다.

**`sshpass -p`는 argv에 비밀번호를 남긴다.** 값 자체는 iCloud에서 잘 관리되지만, `godcprd`가 이를 명령행 인자로 전달합니다. 같은 기기의 다른 프로세스가 `ps`로 볼 수 있습니다. 간접 계층이 파일 시스템까지만 보호하고 프로세스 테이블에서는 끊깁니다. [구조 검토](review-structural-2026-08-26.md)의 S-01 항목을 참고합니다.

## Alternatives considered

git 이력과 저장소 상태에서 읽어낼 수 있는 범위입니다.

**환경변수를 셸 파일에 직접 export.** `README.md.bak`과 `archive/`의 초기 형태가 이 방향이었습니다. 저장소를 공개로 두는 순간 성립하지 않습니다.

**전체 커밋 후 사후 회전.** `.taskmaster/tasks/tasks.json`의 task 14 `[security] shell history 및 추적 env 자격증명 회전`이 이 경로의 잔재이고, `cancelled` 상태로 남아 있습니다. 간접 계층을 도입해 회전이 불필요해졌다는 뜻으로 읽힙니다.

**sops/age 암호화.** `zsh/secrets/dns.zsh`가 `SOPS_AGE_KEY_FILE`을 export하므로 도구는 환경에 있습니다. 하지만 secret 배포에는 쓰이지 않습니다. sops는 암호화된 파일을 커밋할 수 있게 해주지만, 복호화 키 배포 문제를 iCloud로 밀어낼 뿐입니다. 계층을 하나 더 얹는 대신 파일 하나 = 값 하나라는 단순한 형태를 유지하는 선택으로 보입니다.

**Codex 자동 배포.** commit `0819ab3`(`feat(codex): isolate local profile and runtime state`)이 방향을 뒤집었습니다. `bootstrap.sh --ai`는 Codex를 복사하지도 링크하지도 않고 안내만 출력합니다. `zsh/aliases/codex.zsh`의 wrapper가 local profile의 존재·소유자·권한을 검사하고, 없으면 실행을 거부합니다. Codex local profile이 machine-local credential을 담기 때문에, 편의보다 명시적 절차를 택했습니다.

## Related

- [Shell command reference](reference-shell-commands.md): secret loader 함수와 export하는 변수 목록
- [Hermes gateway reference](reference-hermes-gateways.md): `.launchd.env`와 wrapper의 연결
- [Bootstrap CLI reference](reference-bootstrap-cli.md): `sync-secrets`의 검증과 종료 코드
- [How to add configuration](howto-add-configuration.md): allowlist를 넘어 새 파일을 추적하는 절차
- [Configuration architecture](explanation-architecture.md): startup과 runtime sync의 경계
