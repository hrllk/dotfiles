# Hermes gateway reference

Hermes는 Discord를 통해 접근하는 에이전트 런타임입니다. 이 저장소는 Hermes의 **profile 설정과 gateway 실행 wrapper**만 관리하고, 런타임 코드·로그·세션·데이터베이스는 관리하지 않습니다.

배포는 `bootstrap.sh --ai`가 만드는 symlink 하나로 이루어집니다.

```text
~/.hermes -> ~/dotfiles/ai/.hermes
```

secret 흐름의 설계 배경은 [Secret handling](explanation-secret-handling.md)을 참고합니다.

## Tracked surface

`ai/.hermes/.gitignore`는 `*`로 전체를 무시한 뒤 아래 항목만 다시 포함합니다.

| 경로 | 내용 |
|---|---|
| `.env` | 공통 환경 템플릿 |
| `config.yaml` | 기본 profile 설정 |
| `SOUL.md` | 기본 profile 페르소나 |
| `README.md` | 운영 안내 |
| `bin/gateway-*` | profile별 gateway 실행 wrapper |
| `scripts/gateway-restart` | 재시작과 연결 검증 |
| `scripts/sync-secrets` | launchd 환경 파일 생성 |
| `scripts/gateway-management-profile` | profile 생성·삭제 대화형 도구 |
| `profiles/*/.env` | profile별 환경 |
| `profiles/*/config.yaml` | profile별 설정 |
| `profiles/*/SOUL.md` | profile별 페르소나 |

`.launchd.env`는 명시적으로 제외됩니다. 로그, 세션, 메모리, 캐시, `hermes-agent/` 체크아웃은 allowlist에 없으므로 추적되지 않습니다.

> `scripts/`는 세 파일을 **이름으로** 허용합니다. 새 스크립트를 추가하면 자동으로 무시됩니다. 상세는 [구조 검토](review-structural-2026-08-26.md)의 S-05 항목을 참고합니다.

## Profiles

| Profile | `.env` | `config.yaml` | `SOUL.md` | Gateway wrapper |
|---|---|---|---|---|
| (기본) | `ai/.hermes/.env` | `ai/.hermes/config.yaml` | `ai/.hermes/SOUL.md` | `bin/gateway-default` |
| `blog` | 추적됨 | 추적됨 | 추적됨 | `bin/gateway-blog` |
| `config` | 추적됨 | 추적됨 | 추적됨 | `bin/gateway-config` |
| `graphkeeper` | 추적됨 | 추적됨 | 추적됨 | `bin/gateway-graphkeeper`, `bin/gateway-bot-graphkeeper` |
| `jgitkins` | 추적됨 | 추적됨 | 추적됨 | `bin/gateway-jgitkins` |
| `default` | 없음 | 없음 | 추적되지 않음 | `bin/gateway-default` (기본 설정 사용) |

`profiles/default/`는 다른 profile과 형태가 다릅니다. `SOUL.md`만 디스크에 있고 추적되지 않으며 `config.yaml`과 `.env`가 없습니다. `bin/gateway-default`는 `--profile` 없이 실행하므로 실제로는 저장소 루트의 `config.yaml`을 사용합니다.

### `config.yaml` 필드

기본 `ai/.hermes/config.yaml`이 정의하는 값입니다.

| 필드 | 값 | 역할 |
|---|---|---|
| `model.provider` | `openai-codex` | LLM provider |
| `model.base_url` | `https://chatgpt.com/backend-api/codex` | provider endpoint |
| `model.default` | `gpt-5.6-luna` | 기본 모델 |
| `agent.max_turns` | `150` | 세션당 최대 turn |
| `browser.cloud_provider` | `local` | 브라우저 실행 위치 |
| `browser.use_gateway` | `false` | gateway 경유 여부 |
| `display.tool_progress` | `all` | 도구 진행 표시 범위 |
| `command_allowlist` | 목록 | **확인 없이 자동 승인할 작업** |
| `session_reset.mode` | `none` | 세션 초기화 정책 |
| `image_gen.provider` | `openai-codex` | 이미지 생성 provider |
| `platform_toolsets.cli` | 목록 | CLI에서 활성화할 toolset |

### `command_allowlist`

가장 중요한 보안 관련 필드입니다. 여기에 나열한 작업은 **사용자 확인 없이 실행됩니다.** profile마다 값이 다릅니다.

기본 `config.yaml`:

```yaml
command_allowlist:
  - execute_code
  - script execution via -e/-c flag
  - script execution via heredoc
  - shell command via -c/-lc flag
```

profile은 이 목록을 자체적으로 정의합니다. profile을 추가하거나 복제할 때 이 필드를 반드시 검토합니다. `recursive delete`나 `pipe decoded content to shell` 같은 항목은 파괴적이거나 난독화된 명령을 무확인 승인하는 효과가 있습니다.

현재 작업 트리에서 이 목록이 확장된 상태입니다. [구조 검토](review-structural-2026-08-26.md)의 S-02 항목을 참고합니다.

### `.env` 규약

profile `.env`는 secret 값을 담지 않습니다. launchd 환경에서 주입되는 변수를 **참조**합니다.

```env
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN_GRAPHKEEPER}
DISCORD_ALLOWED_USERS=${DISCORD_USER_ID_ALZAR}
```

이 규약 덕분에 `.env`를 저장소에 추적해도 토큰이 노출되지 않습니다. 나머지 항목은 주석 처리된 provider 키 템플릿과 타임아웃·디버그 플래그입니다.

## Gateway wrappers

`ai/.hermes/bin/gateway-<profile>`. launchd가 실행하는 진입점입니다. 모두 같은 형태를 따릅니다.

```zsh
#!/bin/zsh
set -eu

LAUNCHD_ENV="$HOME/.hermes/.launchd.env"
HERMES_PYTHON="$HOME/.hermes/hermes-agent/venv/bin/python"
[[ -r "$LAUNCHD_ENV" ]]
source "$LAUNCHD_ENV"
export DISCORD_BOT_TOKEN="$DISCORD_BOT_TOKEN_<PROFILE>"
export DISCORD_ALLOWED_USERS="$DISCORD_USER_ID_ALZAR"
[[ -n "$DISCORD_BOT_TOKEN" && -n "$DISCORD_ALLOWED_USERS" ]]

exec "$HERMES_PYTHON" -m hermes_cli.main --profile <profile> gateway run --replace
```

`set -eu`와 두 개의 `[[ ]]` 검증이 게이트 역할을 합니다. `.launchd.env`가 없거나 토큰이 비어 있으면 Hermes를 실행하지 않고 즉시 종료합니다.

| Wrapper | 토큰 변수 | `--profile` |
|---|---|---|
| `gateway-default` | `DISCORD_BOT_TOKEN_DEFAULT` | 없음 (기본 설정) |
| `gateway-blog` | `DISCORD_BOT_TOKEN_BLOG` | `blog` |
| `gateway-config` | `DISCORD_BOT_TOKEN_CONFIG` | `config` |
| `gateway-graphkeeper` | `DISCORD_BOT_TOKEN_GRAPHKEEPER` | `graphkeeper` |
| `gateway-jgitkins` | `DISCORD_BOT_TOKEN_JGITKINS` | `jgitkins` |
| `gateway-bot-graphkeeper` | `DISCORD_BOT_TOKEN_GRAPHKEEPER` | `graphkeeper` |

`gateway-management-profile`이 생성하는 wrapper는 `$HOME`을 사용합니다. `gateway-default`와 `gateway-bot-graphkeeper`는 손으로 작성된 초기 파일이라 `/Users/hrk`를 그대로 담고 있습니다. [구조 검토](review-structural-2026-08-26.md)의 S-10 항목을 참고합니다.

`bin/`에는 추적되지 않는 venv 실행 shim(`uv`, `uvx`, `bu`, `tirith`, `browser*`)도 함께 있습니다. 저장소가 관리하는 파일은 `gateway-*`뿐입니다.

## `scripts/gateway-restart`

```text
사용법: gateway-restart --all | [profile ...]
```

secret을 먼저 동기화한 뒤 지정한 gateway를 재시작하고 연결을 검증합니다.

| 인자 | 대상 |
|---|---|
| `--all` | `default` + `profiles/` 아래 모든 디렉터리 |
| `<profile> ...` | 나열한 profile |
| 없음 | usage 출력 후 exit `2` |

| 변수 | 기본값 |
|---|---|
| `HERMES_HOME` | `$HOME/.hermes` |
| `HERMES_BIN` | `hermes` |

동작 순서:

```text
1. scripts/sync-secrets 실행 (없거나 실행 불가면 exit 1)
2. 각 profile에 대해 hermes gateway restart
3. sleep 8
4. 각 profile 로그 마지막 120줄에서
   "Gateway running with 1 platform(s)" 검색
5. 발견 -> "✓ <profile> connected"
   미발견 -> "✗ ... could not be verified" + 로그 경로
```

| 로그 위치 | 대상 |
|---|---|
| `$HERMES_HOME/logs/gateway.log` | `default` |
| `$HERMES_HOME/profiles/<profile>/logs/gateway.log` | 그 외 |

종료 코드는 하나라도 실패하면 `1`, 전부 성공하면 `0`입니다. 재시작 자체가 실패해도 나머지 profile을 계속 처리합니다.

검증 단계는 `rg`(ripgrep)를 사용하며 fallback이 없습니다. `rg`가 없으면 재시작은 되지만 검증이 항상 실패로 보고됩니다. 고정된 `sleep 8`도 느린 환경에서 false negative를 만들 수 있습니다.

```zsh
# 전체 재시작
~/.hermes/scripts/gateway-restart --all

# 특정 profile만
~/.hermes/scripts/gateway-restart graphkeeper jgitkins
```

## `scripts/gateway-management-profile`

profile과 gateway를 함께 만들거나 삭제하는 대화형 도구입니다.

```text
usage: gateway-management-profile [--dry-run]
                                 [--repair PROFILE...]
                                 [-h|--help]
```

| Flag | 역할 |
|---|---|
| `--dry-run` | 계획만 출력. 파일·서비스 변경 없음 |
| `--repair <profile>...` | 프롬프트 없이 wrapper와 LaunchAgent를 재생성 |
| `-h`, `--help` | usage 출력 후 exit `0` |

| 변수 | 기본값 |
|---|---|
| `HERMES_HOME` | `$HOME/.hermes` |
| `HERMES_BIN` | `hermes` |
| `DOTFILES_KEY_DIR` | iCloud `task/keys` |

대화형 모드는 TTY를 요구합니다. 파이프로 실행하면 exit `1`입니다.

### Create flow

메뉴에서 `1`을 선택합니다.

```text
1. 복제할 기존 profile 선택 (0 = 새로 생성)
2. 에이전트 이름 입력        ^[a-z0-9][a-z0-9-]*$ 아니면 exit 2
3. Discord bot token 입력    (silent, 화면에 표시되지 않음)
4. key 파일 생성             umask 077 + atomic replace
5. hermes profile create     (--clone-from 옵션 포함)
6. profile .env 재작성       토큰을 ${DISCORD_BOT_TOKEN_<NAME>} 참조로 변경
7. sync-secrets 실행
8. gateway wrapper 생성      chmod 700
9. LaunchAgent 설치 후 kickstart
10. gateway-restart --all
```

6단계가 핵심입니다. `awk`로 `.env`의 `DISCORD_BOT_TOKEN`과 `DISCORD_ALLOWED_USERS` 줄을 변수 **참조**로 교체하므로, 새로 만든 profile의 `.env`도 토큰 없이 추적할 수 있습니다.

이름 접미사 변환 규칙: 소문자와 하이픈을 대문자와 밑줄로 바꿉니다.

```text
my-agent  ->  DISCORD_BOT_TOKEN_MY_AGENT
```

### Delete flow

메뉴에서 `2`를 선택합니다. `default`는 이 도구로 삭제할 수 없습니다(exit `1`).

```text
1. profile 선택
2. 삭제 확인 (y 아니면 종료)
3. gateway stop -> gateway uninstall -> profile delete --yes
4. key 파일 삭제 여부를 별도로 확인
```

profile 런타임 상태가 함께 제거됩니다. key 파일 삭제는 선택 사항으로 따로 묻습니다.

### Repair flow

wrapper가 오래되었거나 LaunchAgent가 잘못된 실행 파일을 가리킬 때 사용합니다. 프롬프트 없이 wrapper를 다시 쓰고 plist의 `ProgramArguments`를 교체한 뒤 `launchctl`로 재적용합니다.

```zsh
# 계획 확인
~/.hermes/scripts/gateway-management-profile --dry-run --repair graphkeeper

# 실제 재생성
~/.hermes/scripts/gateway-management-profile --repair graphkeeper jgitkins
```

profile 이름은 `^[a-z0-9][a-z0-9-]*$`를 만족해야 하고(exit `2`), `profiles/<name>` 디렉터리가 존재해야 합니다(exit `1`).

## LaunchAgent 연동

| 항목 | 값 |
|---|---|
| Label | `ai.hermes.gateway-<profile>` |
| plist | `~/Library/LaunchAgents/ai.hermes.gateway-<profile>.plist` |
| `ProgramArguments` | `["$HERMES_HOME/bin/gateway-<profile>"]` |
| Domain | `gui/$(id -u)` |

`hermes gateway install`이 만든 plist의 `ProgramArguments`를 `plutil -replace`로 wrapper 경로로 바꿉니다. wrapper를 거치는 이유는 launchd가 로그인 셸 환경을 물려주지 않기 때문입니다. wrapper가 `.launchd.env`를 직접 source해서 필요한 토큰을 주입합니다.

적용은 `launchctl bootout` 후 `bootstrap`, 실패하면 `load -w`로 fallback하고 마지막에 `kickstart -k`를 실행합니다.

## Verification

```zsh
# gateway 목록과 상태
hermes gateway list

# 전체 재시작 후 연결 검증
~/.hermes/scripts/gateway-restart --all

# LaunchAgent 등록 확인
launchctl list | grep ai.hermes

# 추적 대상이 무엇인지 확인
git -C ~/dotfiles status --short ai/.hermes

# launchd 환경 파일 권한 (600이어야 함)
ls -l ~/.hermes/.launchd.env
```

## Related

- [Secret handling](explanation-secret-handling.md): key 파일에서 gateway까지의 간접 계층
- [Bootstrap CLI reference](reference-bootstrap-cli.md): `sync-secrets`의 인터페이스
- [How to add configuration](howto-add-configuration.md): profile 추가 시 추적 여부 확인 절차
- [Project structure reference](project-structure.md): `ai/` 도메인 소유 경계
- [구조 검토](review-structural-2026-08-26.md): allowlist 확장과 경로 하드코딩 등 알려진 문제
