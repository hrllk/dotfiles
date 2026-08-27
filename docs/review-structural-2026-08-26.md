# 구조 검토 (2026-08-26)

문서화 작업 중 저장소 전체를 읽으며 발견한 **구조적 문제와 변경 후보** 목록입니다. 추적 대상 218개 파일의 셸·Bash·설정 표면 전체를 대상으로 했습니다.

세 항목은 실제로 재현했습니다(S-04, S-06, S-07). 나머지는 코드를 읽고 확인한 사실입니다. 재현 여부를 항목마다 표시합니다.

> 이 문서는 **목록**입니다. 아직 아무것도 수정하지 않았습니다. 우선순위와 처리 여부는 결정이 필요합니다.

## 요약

| 등급 | 개수 | 성격 |
|---|---|---|
| HIGH | 3 | 공개 노출, 무확인 승인, credential 유출 경로 |
| MEDIUM | 12 | 동작 버그, 조용한 실패, 규약 위반 |
| LOW | 8 | 위생, 중복, 죽은 코드 |
| DOCS | 4 | 문서와 실제 동작 불일치 |
| TEST | 3 | 위 문제를 통과시킨 커버리지 공백 |

전제 사실 하나: **`github.com/hrllk/dotfiles`는 현재 public입니다.** S-01의 등급은 이 사실에 의존합니다.

```
$ gh repo view hrllk/dotfiles --json visibility
{"visibility":"PUBLIC"}
```

---

## HIGH

### S-01. 사내 인프라 정보와 root 비밀번호 인증 절차가 공개 저장소에 있음

`zsh/aliases/work.zsh:34-56`

세 함수가 사내 데이터센터 IP를 하드코딩하고, root 계정에 비밀번호 인증으로 접속합니다.

| 함수 | 호스트 | 환경 |
|---|---|---|
| `godcprd` | `10.255.x.x` (production) | production |
| `godcstg` | `10.255.x.x` (staging) | staging |
| `godcdev` | `10.255.x.x` (development) | development |

정확한 주소는 `zsh/aliases/work.zsh:37,45,53`에 있습니다. 이 문서도 같은 공개 저장소에 커밋되므로 여기서는 마스킹합니다.

공개된 정보는 사내 사설 대역의 호스트 주소 3개, 환경별 역할 구분, root 로그인이 비밀번호 인증으로 가능하다는 사실, 그리고 공격자가 그대로 쓸 수 있는 명령 형태입니다.

```zsh
"$sshpass_bin" -p "$DC_TRB_PRD" ssh \
  -o PreferredAuthentications=password -o PubkeyAuthentication=no root@<prd-host>
```

비밀번호 값 자체는 안전합니다. iCloud key 파일에서 읽고 저장소에 없습니다. 노출된 것은 **위상과 접근 방식**입니다.

추가로 `sshpass -p <password>`는 비밀번호를 명령행 인자로 전달합니다. 같은 기기의 다른 프로세스가 `ps`로 볼 수 있습니다. `sshpass -e`(환경변수) 또는 `-f`(파일 디스크립터)가 이 노출을 막습니다.

호스트 key 검증(`__godc_require_known_host`)과 key 파일 간접 계층은 잘 만들어져 있습니다. 문제는 이 파일이 공개 저장소에 있다는 것 하나입니다.

변경 후보:
- IP를 key 파일이나 `~/.ssh/config` Host 별칭으로 옮기고 저장소에서 제거
- `sshpass -p`를 `-e` 또는 `-f`로 교체
- 근본적으로는 root 비밀번호 인증 대신 키 기반 인증 + 개별 계정
- 저장소를 private으로 전환하는 것도 선택지이지만, 그것만으로는 이미 공개된 이력이 지워지지 않음

### S-02. Hermes profile이 파괴적 작업을 무확인 승인하도록 확장됨 (커밋되지 않은 변경)

`ai/.hermes/profiles/graphkeeper/config.yaml`, `ai/.hermes/profiles/jgitkins/config.yaml`

작업 트리에 커밋되지 않은 `command_allowlist` 확장이 있습니다. 이 목록의 항목은 **사용자 확인 없이 실행됩니다.**

```diff
  # graphkeeper
   command_allowlist:
  +  - recursive delete

  # jgitkins
   command_allowlist:
  +  - pipe decoded content to shell (possible command obfuscation)
  +  - execute_code
```

`recursive delete`는 재귀 삭제를 무확인 승인합니다. `pipe decoded content to shell`은 항목 이름 자체가 난독화 가능성을 경고합니다. 두 profile 모두 Discord로 접근 가능한 에이전트를 구동합니다.

`DISCORD_ALLOWED_USERS`가 단일 사용자로 제한되어 있어 노출 범위는 좁습니다. 그래도 프롬프트 인젝션 한 번이 확인 절차 없이 재귀 삭제로 이어질 수 있는 조합입니다.

변경 후보:
- 두 항목이 의도한 것인지 확인. 의도라면 왜 필요한지 `docs/decisions.md`에 기록
- `recursive delete`는 제거하고 필요한 경로만 좁혀 허용
- profile 복제 시 allowlist가 함께 복사되므로, 신규 profile 생성 절차에 검토 단계 추가 (이미 [howto-add-configuration](howto-add-configuration.md)에 반영)

### S-03. 모든 git alias가 trace를 강제하고, `gl`은 인증 헤더를 출력할 수 있음

`zsh/aliases/git.zsh:1-27`

27개 alias 중 26개가 `GIT_TRACE=1`을 붙입니다.

```zsh
alias gs='GIT_TRACE=1 git status -sb'
alias gl='GIT_TRACE=1 GIT_TRACE_PACKET=1 GIT_CURL_VERBOSE=1 git pull --rebase'
```

두 가지 문제가 겹칩니다.

**노이즈.** 일상 명령마다 trace 로그가 stderr로 나옵니다. 디버깅용 계측이 영구적으로 켜진 상태입니다.

**credential 노출.** `gl`의 `GIT_CURL_VERBOSE=1`은 HTTP 요청 헤더를 stderr로 출력합니다. HTTPS remote에 credential helper를 쓰면 `Authorization: Basic ...` 헤더가 터미널 스크롤백, `tmux` 캡처 파일, CI 로그에 남을 수 있습니다. `gp`/`gpf`의 `GIT_TRACE_PACKET=1`도 패킷 내용을 출력합니다.

변경 후보:
- 기본 alias에서 trace 변수 제거
- 필요할 때만 켜는 별도 alias 분리 (`gsv`, `glv` 등) 또는 `GIT_TRACE=1 git ...`을 그때 직접 입력
- `GIT_CURL_VERBOSE`는 기본에서 반드시 제거

---

## MEDIUM

### S-04. bootstrap backup이 `BACKUP_ROOT`가 아니라 홈 디렉터리에 생성됨 — **재현됨**

`scripts/bootstrap.sh:106-117`

```zsh
backup_path_for() {
  local candidate="$HOME/${base}.bak.${BACKUP_TIMESTAMP}"     # 첫 시도: $HOME
  while [[ -e "$candidate" || -L "$candidate" ]]; do
    candidate="$BACKUP_ROOT/${base}.bak.${BACKUP_TIMESTAMP}.${suffix}"   # 충돌 시에만 $BACKUP_ROOT
  done
```

일반적인 경우(이름 충돌 없음) backup은 `$HOME`에 생깁니다. `$BACKUP_ROOT`는 이름이 이미 존재할 때만 쓰입니다. 그런데 완료 메시지는 `$BACKUP_ROOT`를 출력합니다.

재현:

```
$ HOME=$T/home BACKUP_ROOT=$T/backup BACKUP_TIMESTAMP=20260826-120000 \
    bash scripts/bootstrap.sh --shell-only
backup: .zshrc -> .zshrc.bak.20260826-120000
backup: .wezterm.lua -> .wezterm.lua.bak.20260826-120000
bootstrap completed. backups: $T/backup timestamp: 20260826-120000

$ ls -A $T/backup
(비어 있음)
$ ls -A $T/home | grep bak
.wezterm.lua.bak.20260826-120000
.zshrc.bak.20260826-120000
```

같은 이름의 함수가 `ai/.claude/scripts/link-claude-home:63-74`에 따로 구현되어 있고, 그쪽은 **정확합니다.** 항상 `$BACKUP_ROOT`에 씁니다. 두 복사본이 갈라진 상태입니다.

영향: 재설치를 반복하면 홈 디렉터리에 `.bak.*` 파일이 쌓이고, `$BACKUP_ROOT`를 정리해도 실제 backup은 남습니다. 메시지가 알려주는 위치에 파일이 없으므로 복구 시 혼란이 생깁니다.

변경 후보:
- `backup_path_for`의 첫 candidate를 `$BACKUP_ROOT`로 수정
- 두 구현을 공유 스크립트로 합치기
- S-25의 테스트를 함께 추가

### S-05. allowlist gitignore가 새 파일을 조용히 무시함

`ai/.codex/.gitignore:1`, `ai/.hermes/.gitignore:1`

`ai/.codex/.gitignore`는 `*`로 전체를 무시한 뒤 **세 파일만** 다시 포함합니다.

```gitignore
*
!.gitignore
!config.toml
!local.config.toml.example
!codex-profile-check
```

그런데 `ai/.codex/` 아래에는 40개가 넘는 파일이 추적되고 있습니다. `skills/` 20개, `scripts/` 7개, `docs/` 3개, `.github/` 5개, `AGENTS.md`, `CLAUDE.md` 등. allowlist 도입 전에 추가되어 계속 추적되는 파일들입니다(gitignore는 이미 추적 중인 파일에 영향을 주지 않음).

결과적으로 **같은 디렉터리에서 파일마다 동작이 다릅니다.**

```
$ git check-ignore -v ai/.codex/skills/NEWSKILL/SKILL.md
ai/.codex/.gitignore:1:*	ai/.codex/skills/NEWSKILL/SKILL.md

$ git ls-files ai/.codex/skills | wc -l
20
```

새 skill을 추가하면 `git status`에 나타나지 않고, `git add`는 조용히 아무 일도 하지 않습니다.

같은 문제가 `ai/.hermes/scripts/`에도 있습니다. allowlist가 세 파일을 **이름으로** 허용합니다.

```gitignore
!scripts/gateway-restart
!scripts/sync-secrets
!scripts/gateway-management-profile
```

`ai/.hermes/scripts/restart-default-gateway.py`는 디스크에 있지만 추적되지 않습니다.

`ai/.codex/.gitignore`에는 `*` 아래에 `node_modules/`, `auth.json`, `cache/`, `sessions/` 등 30줄이 넘는 denylist도 있습니다. `*`가 이미 전부 무시하므로 이 줄들은 기능적으로 무의미합니다. 의도 문서화로는 가치가 있지만, 읽는 사람에게 "denylist 방식"이라는 잘못된 인상을 줍니다.

allowlist 자체는 옳은 선택입니다([Secret handling](explanation-secret-handling.md) 참고). 문제는 범위가 실제 추적 대상과 맞지 않는다는 것입니다.

변경 후보:
- `ai/.codex/.gitignore`의 allowlist를 실제 추적 중인 경로(`skills/`, `scripts/`, `docs/`, `.github/`, `AGENTS.md`, `CLAUDE.md`, `hooks/`, `tasks/`)까지 확장
- `ai/.hermes`의 `scripts/`를 이름 목록에서 확장자·디렉터리 패턴으로 전환
- `*` 아래의 죽은 denylist는 주석으로 강등하거나 제거
- S-27의 테스트 추가

### S-06. lazy loader가 실패해도 자신을 먼저 제거해 진단이 한 번만 나옴 — **재현됨**

`zsh/integrations/lazy/sdkman.zsh:17-21`, `zsh/integrations/lazy/nvm.zsh:46-57`

```zsh
sdk() {
  unset -f sdk          # 실패 여부와 무관하게 먼저 제거
  __load_sdkman || return $?
  sdk "$@"
}
```

도구가 설치되지 않은 환경에서 첫 호출은 안내를 출력하지만, 두 번째 호출은 함수가 이미 없어서 `command not found`가 됩니다.

재현:

```
$ HOME=$T/home zsh -fc 'source zsh/integrations/lazy/sdkman.zsh
> sdk version; sdk version'
sdkman loader not found: $T/home/.sdkman/bin/sdkman-init.sh   # 1회
exit=127
zsh: command not found: sdk                                    # 2회
exit=127
```

`nvm`도 동일합니다. 종료 코드는 우연히 둘 다 `127`이라 스크립트 동작은 바뀌지 않습니다. 문제는 **진단 메시지가 사라진다**는 것입니다. 사용자는 첫 호출을 놓치면 무엇을 설치해야 하는지 알 수 없습니다.

`docs/explanation-architecture.md`는 "calling `sdk` then returns `127` with one diagnostic line"이라고 서술합니다. 첫 호출에만 맞는 설명입니다.

변경 후보:
- `unset -f`를 성공 경로로 이동

  ```zsh
  sdk() {
    __load_sdkman || return $?
    unset -f sdk
    sdk "$@"
  }
  ```
- S-26의 테스트 보강

### S-07. `secrets/personal.zsh`만 eager 로드라 매 셸 시작마다 오류 3줄 — **재현됨**

`zsh/secrets/personal.zsh:1-6`

다른 세 도메인은 loader 함수로 감싸 지연 로드합니다. `personal.zsh`만 top-level에서 즉시 실행합니다.

| 파일 | 방식 |
|---|---|
| `ai.zsh` | `load_ai_keys()` |
| `dns.zsh` | `load_dns_keys()` |
| `work.zsh` | `load_work_keys()`, `load_oke_vars()` |
| `personal.zsh` | **top-level `__export_secret` × 3** |

key 파일이 없는 환경에서 재현:

```
$ DOTFILES_KEY_DIR=$T/keys zsh -f -c 'source zsh/secrets/index.zsh; echo "[done]"'
secret file not readable
secret file not readable
secret file not readable
[done]
```

새 Mac에서 [tutorial](tutorial-first-setup.md)을 따라가면 셸을 열 때마다 원인을 알 수 없는 오류 세 줄을 보게 됩니다. 어느 변수인지, 어떤 파일인지 알려주지 않습니다.

부수적으로 세 가지가 더 어긋납니다.

- 셸 시작마다 iCloud 경로 파일 3개를 읽습니다. 저장소가 명시한 "빠른 startup" 목표와 반대 방향입니다.
- `load_all_keys`는 `personal.zsh`를 다루지 않습니다. "모든 키 로드"라는 이름과 실제 범위가 다릅니다.
- 데이터센터 비밀번호는 지연 로드로 노출 범위를 줄였는데, Discord 토큰은 모든 셸 환경에 상주합니다. 기준이 일관되지 않습니다.

변경 후보:
- `load_personal_keys()`로 감싸고 `load_all_keys`에 등록
- Hermes gateway는 `.launchd.env`를 쓰므로 셸 환경의 Discord 토큰이 실제로 필요한지 확인. 불필요하면 지연 로드로 전환
- `__export_secret`의 오류 메시지에 변수 이름 포함 (값은 계속 감춤)

### S-08. `tree` 함수가 대상 디렉터리를 받지 못함

`zsh/aliases/navigation.zsh:12-30`

```zsh
tree() {
  local depth=1
  local mode="all"
  [[ -n "$1" ]] && depth=$1
  [[ -n "$2" ]] && mode=$2
  ...
    colorls "${dir:-.}" -l --tree="${depth}" --sd --sf
```

`dir`은 이 함수 어디에서도 대입되지 않습니다. `local dir`도 없습니다. 따라서 `${dir:-.}`는 항상 `.`로 평가되고, 대상 디렉터리를 지정할 방법이 없습니다.

더 나쁜 경우: 셸에 전역 `dir` 변수가 있으면 그 값이 새어 들어옵니다.

```zsh
dir=/etc
tree 2        # /etc 를 대상으로 동작
```

이 함수는 시스템 `tree` 실행 파일도 가립니다.

변경 후보:
- 세 번째 인자로 대상 경로를 받고 `local dir="${3:-.}"` 선언
- 또는 `${dir:-.}`를 `.`로 고정해 의도를 명확히

### S-09. 추적하면 안 되는 파일들이 추적 중

| 파일 | 문제 |
|---|---|
| `.DS_Store` | `.gitignore`에 있는데도 추적됨. gitignore는 이미 추적 중인 파일에 영향 없음 |
| `README.md.bak` | 79줄짜리 구버전 README |
| `archive/ai/.gemini/installation_id` | 36바이트 기기 식별자 |
| `archive/ai/.codex/AGENTS.md.bak` | backup 파일 |
| `archive/ai/.gemini/GEMINI.md.bak` | backup 파일 |

`docs/project-structure.md`는 `README.md.bak`을 "historical"로 분류해 존재를 인정하지만, `.DS_Store`와 `installation_id`는 어느 분류에도 맞지 않습니다.

변경 후보:

```zsh
git rm --cached .DS_Store README.md.bak
git rm --cached archive/ai/.gemini/installation_id
git rm --cached archive/ai/.codex/AGENTS.md.bak archive/ai/.gemini/GEMINI.md.bak
printf '%s\n' '*.bak' >> .gitignore
```

`installation_id`는 이력에도 남으므로 필요하면 별도 처리.

### S-10. `/Users/hrk` 하드코딩이 5개 추적 파일에 있음

| 파일 | 비고 |
|---|---|
| `ai/.hermes/bin/gateway-default` | `$HOME`을 쓰는 다른 wrapper와 불일치 |
| `ai/.hermes/bin/gateway-bot-graphkeeper` | 동일 |
| `ai/.claude/settings.json` | hook 명령 경로 |
| `util/wezterm/wezterm.lua` | 터미널 설정 |
| `zsh/tests/startup-isolation-test.zsh` | 테스트 fixture |

주목할 점: `gateway-management-profile:82-83`이 **생성하는** wrapper는 `$HOME`을 씁니다. 즉 생성기는 올바르고, 손으로 쓴 초기 파일 두 개만 드리프트한 상태입니다.

```
gateway-blog          $HOME (portable)
gateway-bot-graphkeeper  HARDCODED /Users/hrk
gateway-config        $HOME (portable)
gateway-default       HARDCODED /Users/hrk
gateway-graphkeeper   $HOME (portable)
gateway-jgitkins      $HOME (portable)
```

`README.md`는 "The current layout is optimized for this machine, not for full portability"라고 밝히므로 의도된 범위 안일 수 있습니다. 그래도 같은 종류 파일 사이의 불일치는 남습니다.

변경 후보:
- `~/.hermes/scripts/gateway-management-profile --repair default bot-graphkeeper`로 두 wrapper 재생성
- 나머지 3개는 의도된 machine-local로 두고 `docs/decisions.md`에 기록

### S-11. `ai/.hermes/bin/`이 관리 대상과 런타임 shim을 섞어 둠

```
tracked   gateway-blog, gateway-bot-graphkeeper, gateway-config,
          gateway-default, gateway-graphkeeper, gateway-jgitkins
UNTRACKED browser, browser-use, browser-use-tui, browseruse, bu,
          tirith, uv, uvx
```

`docs/project-structure.md`가 직접 명시한 원칙과 충돌합니다.

> 새 설정을 추가할 때는 먼저 소유 영역을 정하고, active source와 runtime output을 같은 디렉터리에 섞지 않는 것을 원칙으로 합니다.

`bin/`이 정확히 그 상태입니다. allowlist(`!bin/gateway-*`)가 실질적으로 걸러주고 있어 사고는 나지 않지만, `bin/`을 보는 사람은 무엇이 저장소 소유인지 알 수 없습니다.

변경 후보:
- gateway wrapper를 `bin/gateway/`처럼 별도 하위 디렉터리로 분리
- 또는 `ai/.hermes/README.md`에 `bin/`의 혼재 상태를 명시

### S-12. `profiles/default/`가 다른 profile과 형태가 다름

```
blog         .env=tracked  config.yaml=tracked  SOUL.md=tracked
config       .env=tracked  config.yaml=tracked  SOUL.md=tracked
graphkeeper  .env=tracked  config.yaml=tracked  SOUL.md=tracked
jgitkins     .env=tracked  config.yaml=tracked  SOUL.md=tracked
default      .env=MISSING  config.yaml=MISSING  SOUL.md=UNTRACKED
```

`git status`에 `?? ai/.hermes/profiles/default/`로 남아 있습니다. allowlist는 `profiles/*/SOUL.md`를 허용하므로 추적 **가능한** 상태인데 추가되지 않았습니다.

`bin/gateway-default`는 `--profile` 없이 실행하므로 실제로는 루트 `config.yaml`을 씁니다. 그렇다면 `profiles/default/`가 왜 존재하는지가 불분명합니다.

변경 후보:
- `SOUL.md`가 실제로 쓰이면 추적 대상에 추가
- 쓰이지 않으면 디렉터리 제거
- 어느 쪽이든 `gateway-default`가 루트 설정을 쓴다는 사실을 문서화 (이미 [reference-hermes-gateways](reference-hermes-gateways.md)에 반영)

### S-13. `zcompdump` staleness 검사가 두 파일만 봄

`zsh/options/completion.zsh:25`

```zsh
if [[ ! -s "$zcompdump" || "$zcompdump" -ot "$HOME/.zshrc" \
      || "$zcompdump" -ot "$ZSH_DOTFILES_PATH/options/completion.zsh" ]]; then
```

`.zshrc`와 `completion.zsh`의 mtime만 확인합니다. `plugins/omz/fzf-tab.zsh`처럼 completion 동작을 바꾸는 다른 모듈을 수정해도 dump가 재생성되지 않습니다. 증상은 "설정을 고쳤는데 completion이 그대로"입니다.

변경 후보:
- `zsh/` 아래 최신 mtime과 비교하거나, completion에 영향을 주는 파일 목록을 명시적으로 나열
- 최소한 [howto-add-configuration](howto-add-configuration.md)에 수동 무효화 절차 안내 (반영됨)

### S-14. 자동 reload가 sourcing된 모듈을 감시하지 않음

`zsh/.zshrc:37-65`

`ZSH_AUTO_RELOAD=1`일 때 `reload_zshrc`가 `precmd`에 등록되지만, 감시 대상은 `.zshrc`와 `.p10k.zsh` 두 개입니다. `aliases/git.zsh`를 고쳐도 reload가 걸리지 않습니다.

기본값이 off이므로 영향 범위는 좁습니다. 다만 기능 이름("auto reload")과 실제 범위가 다릅니다.

변경 후보: 감시 대상을 `zsh/` 전체 최신 mtime으로 확장, 또는 기능 범위를 문서에 명시

### S-15. `HISTSIZE`가 `SAVEHIST`보다 커서 종료 시 이력이 잘림

`zsh/options/history.zsh:3-4`

```zsh
HISTSIZE=50000
SAVEHIST=20000
```

메모리에는 50,000개를 유지하지만 파일에는 20,000개만 씁니다. 셸을 닫을 때 30,000개가 조용히 사라집니다. 커밋 `3a7478c fix(zsh): restore persistent command history`의 의도(이력 영속화)와 어긋나는 방향입니다.

변경 후보: `SAVEHIST`를 `HISTSIZE` 이상으로 (일반적으로 동일하게)

---

## LOW

### S-16. `SDKMAN_DIR`과 `NVM_DIR`이 사용자 설정을 덮어씀

`zsh/integrations/lazy/sdkman.zsh:1`, `zsh/integrations/lazy/nvm.zsh:1`

```zsh
export SDKMAN_DIR="$HOME/.sdkman"     # 기존 값 무시
export NVM_DIR="$HOME/.nvm"           # 동일
```

저장소의 다른 곳은 일관되게 `${VAR:-default}`를 씁니다(`DOTFILES_DIR`, `BACKUP_ROOT`, `CODEX_HOME`, `HERMES_HOME`, `DOTFILES_KEY_DIR`). 이 두 줄만 예외입니다. SDKMAN을 다른 위치에 설치한 기기에서는 재정의할 방법이 없습니다.

변경 후보: `export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"`

### S-17. `gateway-restart`가 `rg`에 의존하고 고정 `sleep`을 씀

`ai/.hermes/scripts/gateway-restart:54,61`

```zsh
sleep 8
... | rg -q 'Gateway running with 1 platform\(s\)'
```

`rg`(ripgrep) 미설치 시 검증이 항상 실패로 보고됩니다. 재시작 자체는 되므로 false negative입니다. `README.md`의 선택 도구 목록에 `rg`가 없습니다.

`sleep 8`은 느린 환경에서 부족할 수 있습니다.

변경 후보: `grep -q`로 교체(패턴이 특별한 기능을 쓰지 않음), 또는 시작 시 `rg` 존재 확인. `sleep`은 타임아웃 있는 폴링으로.

### S-18. `gateway-restart`의 `log_file` 대입이 죽은 코드

`ai/.hermes/scripts/gateway-restart:46,50`

첫 번째 루프에서 `log_file`을 대입하지만 그 루프 안에서 쓰지 않습니다. 두 번째 루프가 사용 전에 다시 대입합니다. 첫 루프의 두 줄은 제거 가능합니다.

### S-19. `link-claude-home`의 prefix 조작이 무의미

`ai/.claude/scripts/link-claude-home:73`

```zsh
printf '%s/%s\n' "$BACKUP_ROOT" "${candidate#"$BACKUP_ROOT/"}"
```

`candidate`는 이미 `$BACKUP_ROOT/`로 시작합니다. prefix를 떼고 다시 붙이는 동작이므로 결과는 `$candidate`와 동일합니다.

변경 후보: `printf '%s\n' "$candidate"`

### S-20. `env.zsh`가 전역 변수를 남김 — **재현됨**

`zsh/env.zsh:14`

```zsh
local_java_home="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
```

sourcing된 파일의 top-level이므로 `local`이 아니라 전역입니다. 이름이 `local_`로 시작해 의도를 표현했지만 실제 동작은 전역이고, 이후 `unset`하지 않습니다.

SDKMAN이 없는 기기에서 재현:

```
$ HOME=$T/home zsh -f -c 'source zsh/env.zsh; echo ${local_java_home+set}'
LEAKED as global: local_java_home=<empty>
```

같은 파일에서 만든 다른 변수들은 의도적으로 export되는 값입니다. 이 하나만 내부 계산용입니다.

변경 후보: 사용 후 `unset local_java_home`, 또는 함수로 감싸기

### S-21. `path.zsh`의 중복 제거가 이중으로 수행됨

`zsh/path.zsh:1,44`

```zsh
typeset -gU path      # 1행: path를 unique 배열로 선언
...
path=("${(@u)path}")  # 44행: 다시 중복 제거
```

`typeset -U`가 대입 시점에 중복을 제거하므로 44행은 불필요합니다. 동작은 정확하지만 독자에게 "중복 제거가 자동이 아닌가?"라는 의문을 남깁니다.

### S-22. 바이너리 자산 14MB가 저장소에 있음

`util/assets/wallpapers/` 아래 JPG 10개, 총 14MB. `.git`은 67MB입니다.

`docs/project-structure.md`는 "terminal이 참조하는 정적 이미지"로 설명하지만, 실제로 참조하는 설정이 있는지 확인이 필요합니다.

변경 후보: 실제 참조 여부 확인 후, 참조되지 않으면 제거하거나 별도 저장소로 분리

### S-23. `archive/`가 추적 파일의 26%를 차지

56개 파일(전체 218개 중)이 `archive/` 아래 있고, 대부분 더 이상 로드되지 않는 Gemini/Codex 설정입니다. `README.md`와 `project-structure.md`가 "historical"로 명시해 혼란은 방지하고 있습니다.

변경 후보: git 이력에 남아 있으므로 삭제 가능. 유지한다면 현재 상태가 적절함. 판단 필요.

---

## DOCS

### S-24. tutorial이 Codex 연결 단계를 빠뜨림

`docs/tutorial-first-setup.md` Step 5

원문은 symlink 확인만 안내했습니다.

```markdown
Codex 설정이 저장소의 `ai/.codex`를 사용하려면 다음 symlink를 확인합니다.
ls -ld ~/.codex
```

symlink 자체는 실제로 존재합니다. `ai/.codex/init-home-codex:31`이 `~/.codex -> ai/.codex`를 만듭니다. 문제는 **누가 그것을 만드는지 tutorial이 말하지 않는다**는 점입니다.

`scripts/bootstrap.sh:203`은 안내 문장만 출력하고 링크하지 않습니다.

```zsh
printf 'Codex local profile guidance: create %s/local.config.toml explicitly; \
no automatic copy or link was performed.\n' "$HOME/.codex"
```

따라서 tutorial을 그대로 따라가면 `ls -ld ~/.codex`는 실패합니다. `init-home-codex` 실행과 `local.config.toml` 생성이 빠져 있고, 그것이 없으면 `codex` wrapper가 실행을 거부합니다(`zsh/aliases/codex.zsh:11-15`).

이 항목은 Step 5에 연결·profile 생성 절차를 추가해 수정했습니다.

### S-25. backup 경로 서술이 문서 간에 다름

| 문서 | 서술 |
|---|---|
| `docs/explanation-architecture.md` | `~/.zshrc.bak.YYYYMMDD-HHMMSS` (홈 디렉터리) |
| `docs/project-structure.md` | `BACKUP_ROOT` 기본값 `$HOME/.dotfiles-backup`이 "backup root" |
| `README.md` | "backs up existing shell and terminal config files" (위치 미명시) |

`explanation-architecture.md`가 우연히 실제 동작(S-04)과 일치하고, `project-structure.md`가 의도된 동작을 설명합니다. 코드 버그가 문서 불일치로 드러난 형태입니다.

S-04를 고치면 `explanation-architecture.md`를 함께 수정해야 합니다. 지금은 [reference-bootstrap-cli.md](reference-bootstrap-cli.md)에 실제 동작을 명시해 두었습니다.

### S-26. 문서 언어가 갈라짐

| 범위 | 언어 |
|---|---|
| `README.md` | 영어. 단 "Targets after bootstrap" 목록에 한국어 2줄 |
| `docs/*.md` | 한국어 |
| `docs/explanation-architecture.md` | 한국어. "Startup and runtime sync boundaries" 절만 영어 |
| 코드 주석 | 영어 (`completion.zsh:9`만 한국어) |

새로 쓴 문서는 `docs/` 관례에 맞춰 한국어로 작성했습니다. 판단 필요: README를 한국어로 통일할지, `docs/`를 영어로 통일할지, 현재 분리를 의도로 유지할지.

### S-27. 문서 진입점이 불완전했음

`docs/index.md`가 AI 도메인 문서(Hermes gateway, secret 흐름)를 안내하지 않았고, `README.md`는 `project-structure.md`를 "public shell commands"를 다루는 문서로 소개하지만 실제로 명령 목록은 없었습니다.

이 항목은 아래에서 해결했습니다.

---

## TEST

### S-28. bootstrap이 `BACKUP_ROOT`를 채우는지 검증하는 테스트가 없음

`scripts/tests/bootstrap-matrix-test.sh:63`은 dry-run이 `BACKUP_ROOT`를 **만들지 않는지** 확인합니다.

```zsh
fail "$label created BACKUP_ROOT during dry-run"
```

실제 실행이 `BACKUP_ROOT`에 **쓰는지** 확인하는 단정은 어디에도 없습니다. S-04가 통과한 경로입니다.

`claude-backup-contract-test.sh`는 `link-claude-home`에 대해 그 검증을 정확히 수행합니다(`$TEST_ROOT/backup/.claude.bak.*.1` 존재 확인). 두 스크립트 사이의 커버리지 비대칭이 두 구현의 드리프트를 허용했습니다.

변경 후보:

```zsh
[[ -f "$TEST_ROOT/backup/.zshrc.bak.$TS" ]] || fail "backup was not written to BACKUP_ROOT"
[[ ! -e "$TEST_ROOT/home/.zshrc.bak.$TS" ]] || fail "backup leaked into HOME"
```

### S-29. lazy loader 테스트가 반복 호출을 다루지 않음

`zsh/tests/sdkman-lazy-test.zsh:15`

미설치 fixture에서 `sdk`를 **한 번만** 호출합니다.

```zsh
HOME="$TEST_ROOT/uninstalled" zsh -fc 'source "$1"; sdk test'
```

설치된 fixture는 `sdk first; sdk second`로 두 번 호출해 초기화가 1회만 일어나는지 확인합니다. 실패 경로에는 같은 검증이 없어 S-06을 놓쳤습니다.

`nvm`에는 동등한 테스트 파일 자체가 없습니다.

변경 후보:

```zsh
HOME="$TEST_ROOT/uninstalled" zsh -fc 'source "$1"; sdk test; sdk test' ...
# stderr가 2줄이고 두 줄 모두 loader 메시지인지 확인
```

### S-30. gitignore allowlist 계약을 검증하는 테스트가 없음

S-05는 정적으로 검증 가능합니다.

```zsh
# 추적 중인 모든 파일이 지금도 추적 가능해야 한다
for f in $(git ls-files ai/); do
  git check-ignore -q "$f" && fail "tracked but now ignored: $f"
done
```

이 단정이 있으면 allowlist와 실제 추적 대상의 드리프트가 즉시 드러납니다.

---

## 처리 순서 제안

의존 관계와 위험도를 함께 고려한 순서입니다.

| 순서 | 항목 | 근거 |
|---|---|---|
| 1 | S-01 | 공개 노출. 되돌리기 가장 어려움 |
| 2 | S-02 | 커밋 전에 판단해야 함 |
| 3 | S-03 | 한 줄 변경으로 credential 노출 경로 제거 |
| 4 | S-04 + S-28 | 버그와 그것을 통과시킨 테스트를 함께 |
| 5 | S-06 + S-29 | 동일 |
| 6 | S-05 + S-30 | 동일. 이후 작업의 커밋 누락을 방지 |
| 7 | S-07 | 새 기기 첫 인상에 직접 영향 |
| 8 | S-09, S-15, S-16, S-19, S-20, S-21 | 저위험 위생 작업. 묶어서 처리 가능 |
| 9 | S-08, S-13, S-14, S-17, S-18 | 동작 개선 |
| 10 | S-10, S-11, S-12, S-22, S-23, S-26 | 판단이 필요한 구조·범위 결정 |

S-24와 S-27은 이 작업에서 이미 수정했습니다. S-25는 S-04를 고칠 때 함께 처리합니다.

## Related

- [Shell command reference](reference-shell-commands.md)
- [Bootstrap CLI reference](reference-bootstrap-cli.md)
- [Hermes gateway reference](reference-hermes-gateways.md)
- [Secret handling](explanation-secret-handling.md)
- [How to add configuration](howto-add-configuration.md)
- [decisions.md](decisions.md): 결정을 기록할 위치
