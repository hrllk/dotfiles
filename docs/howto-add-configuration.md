# How to add configuration

새 alias, 모듈, plugin, Hermes profile을 추가하는 절차입니다. 각 절차의 마지막에 **추적 여부 확인** 단계가 있습니다. `ai/` 아래 디렉터리는 allowlist 방식 gitignore를 쓰기 때문에, 파일을 만들어도 `git status`에 나타나지 않는 경우가 있습니다.

소유 경계는 [Project structure reference](project-structure.md), 로드 순서는 [Configuration architecture](explanation-architecture.md)를 참고합니다.

## Prerequisites

- 저장소가 `~/dotfiles`에 clone되어 있고 bootstrap이 완료된 상태
- `~/.zshrc`가 저장소를 가리키는 symlink

```zsh
readlink ~/.zshrc   # ~/dotfiles/zsh/.zshrc 를 출력해야 함
```

---

## 새 alias 추가

### Steps

1. 도메인에 맞는 파일을 고릅니다.

   | 성격 | 파일 |
   |---|---|
   | 디렉터리 이동, 파일 목록 | `zsh/aliases/navigation.zsh` |
   | git | `zsh/aliases/git.zsh` |
   | 외부 CLI 단축 | `zsh/aliases/tools.zsh` |
   | 업무용 함수 | `zsh/aliases/work.zsh` |
   | Codex | `zsh/aliases/codex.zsh` |
   | 그 외 | `zsh/aliases/others.zsh` |

2. alias를 추가합니다. 외부 도구에 의존하면 존재를 확인합니다.

   ```zsh
   if command -v bat >/dev/null 2>&1; then
     alias cat='bat --style=plain'
   fi
   ```

3. 셸을 다시 시작하고 확인합니다.

   ```zsh
   exec zsh
   type cat
   ```

`aliases/index.zsh`는 여섯 파일을 고정 목록으로 source합니다. **새 파일을 만들면 이 목록에 직접 추가해야 합니다.**

```zsh
# zsh/aliases/index.zsh
for alias_file in \
  "$ZSH_DOTFILES_PATH/aliases/navigation.zsh" \
  ...
  "$ZSH_DOTFILES_PATH/aliases/mynew.zsh"
```

### Verification

```zsh
type <alias-name>          # alias 또는 function으로 보고되어야 함
zsh -i -c exit             # 오류 출력이 없어야 함
```

새 alias는 [Shell command reference](reference-shell-commands.md)에도 추가합니다.

---

## 새 zsh 모듈 추가

`.zshrc`는 명시적 목록을 순서대로 source합니다. 자동 탐색은 없습니다.

### Steps

1. 파일을 만듭니다. 위치는 책임에 따라 정합니다.

   | 책임 | 위치 |
   |---|---|
   | 셸 옵션, completion, keybinding | `zsh/options/` |
   | 외부 도구 경로값 계산 | `zsh/integrations/` |
   | 첫 호출 시 초기화하는 도구 | `zsh/integrations/lazy/` |
   | plugin 설정 | `zsh/plugins/omz/` 또는 `zsh/plugins/custom/` |
   | secret 도메인 | `zsh/secrets/` |

2. `zsh/.zshrc`의 올바른 위치에 `source_if_exists` 줄을 추가합니다. 순서가 중요합니다.

   ```text
   env.zsh          환경변수 정의
   integrations/    경로값 계산 (PATH는 아직 건드리지 않음)
   path.zsh         PATH 확정  <- 경로를 등록하려면 이 앞에서 값을 만들어야 함
   secrets/         secret loader
   aliases/         alias와 함수
   plugins/         plugin과 theme
   ```

3. PATH에 경로를 추가하려면 `path.zsh`만 수정합니다. 다른 모듈에서 `PATH`나 `path`를 직접 변경하지 않습니다. 이 규칙은 `zsh/tests/path-ownership-test.zsh`가 검증합니다.

   ```zsh
   # zsh/integrations/mytool.zsh — 값만 계산
   if [[ -d "$HOME/.mytool" ]]; then
     typeset -g MYTOOL_BIN_DIR="$HOME/.mytool/bin"
   fi
   ```

   ```zsh
   # zsh/path.zsh — 등록은 여기서
   path_add "${MYTOOL_BIN_DIR:-}"
   ```

4. lazy loader를 만들 때는 실패 경로를 먼저 검사하고 나중에 `unset -f`합니다.

   ```zsh
   mytool() {
     __load_mytool || return $?     # 검사를 먼저
     unset -f mytool                # 성공한 뒤에 제거
     mytool "$@"
   }
   ```

   기존 `sdk`와 `nvm` wrapper는 순서가 반대라서 진단 메시지가 첫 호출에만 나옵니다. 새 loader는 이 형태를 따르지 않습니다. [구조 검토](review-structural-2026-08-26.md)의 S-06 항목을 참고합니다.

5. completion 동작을 바꿨다면 `zcompdump`를 무효화합니다.

   ```zsh
   rm -f ~/.zcompdump-*
   exec zsh
   ```

   staleness 검사는 `.zshrc`와 `options/completion.zsh`의 mtime만 봅니다. 다른 모듈을 고쳐도 자동으로 재생성되지 않습니다.

### Verification

```zsh
zsh -i -c exit                              # 오류 없이 종료
time zsh -i -c exit                         # startup 시간 확인
zsh zsh/tests/path-ownership-test.zsh       # PATH 소유권 유지
zsh zsh/tests/startup-isolation-test.zsh    # startup 부작용 없음
```

---

## 새 secret 도메인 추가

### Steps

1. key 파일을 만듭니다. 파일 하나에 값 하나, 저장소 밖입니다.

   ```zsh
   mkdir -p "$DOTFILES_KEY_DIR/mydomain"
   printf '%s\n' 'the-secret-value' > "$DOTFILES_KEY_DIR/mydomain/my-token"
   chmod 600 "$DOTFILES_KEY_DIR/mydomain/my-token"
   ```

2. `zsh/secrets/mydomain.zsh`를 만듭니다. **함수로 감쌉니다.**

   ```zsh
   load_mydomain_keys() {
     __export_secret MY_TOKEN "$DOTFILES_KEY_DIR/mydomain/my-token"
   }
   ```

   top-level에서 `__export_secret`을 호출하면 셸을 열 때마다 파일을 읽고, 파일이 없으면 매번 오류를 출력합니다.

3. `zsh/secrets/index.zsh`의 source 목록과 `load_all_keys`에 추가합니다.

   ```zsh
   for secret_file in \
     ...
     "$ZSH_DOTFILES_PATH/secrets/mydomain.zsh"

   load_all_keys() {
     ...
     typeset -f load_mydomain_keys >/dev/null 2>&1 && load_mydomain_keys
   }
   ```

4. 값을 사용하는 함수에서 loader를 먼저 호출합니다.

   ```zsh
   mycommand() {
     load_mydomain_keys || return $?
     curl -H "Authorization: Bearer $MY_TOKEN" ...
   }
   ```

### Verification

```zsh
exec zsh
type -f load_mydomain_keys load_all_keys
load_mydomain_keys && [[ -n "$MY_TOKEN" ]] && echo ok
git -C ~/dotfiles status --short          # key 파일이 나타나면 안 됨
```

값을 저장소 파일이나 문서에 절대 쓰지 않습니다. 설계 배경은 [Secret handling](explanation-secret-handling.md)에 있습니다.

---

## `ai/` 아래에 새 파일 추적하기

`ai/.claude`, `ai/.codex`, `ai/.hermes`는 각자 `.gitignore`에서 `*`로 전체를 무시한 뒤 allowlist로 예외를 지정합니다. **allowlist에 없는 새 파일은 조용히 무시됩니다.**

기존에 추적되던 파일들은 allowlist 도입 전에 추가되어 계속 추적됩니다. 그래서 같은 디렉터리에서 파일마다 동작이 다릅니다. `ai/.codex/skills/`에는 추적되는 파일이 20개 있지만, 새로 만든 skill은 무시됩니다.

### Steps

1. 파일을 만든 뒤 **먼저 무시되는지 확인합니다.**

   ```zsh
   git -C ~/dotfiles check-ignore -v ai/.codex/skills/myskill/SKILL.md
   ```

   출력이 있으면 무시되는 상태이고, 어느 `.gitignore`의 몇 번째 줄이 원인인지 알려줍니다.

   ```text
   ai/.codex/.gitignore:1:*	ai/.codex/skills/myskill/SKILL.md
   ```

   출력이 없으면 이미 추적 가능합니다. 3단계로 갑니다.

2. 해당 `.gitignore`에 re-include 규칙을 추가합니다. 디렉터리와 파일을 모두 열어야 합니다.

   ```gitignore
   !skills/
   !skills/**/
   !skills/**/*.md
   ```

   `!skills/**/`(중간 디렉터리) 줄이 없으면 하위 파일 규칙이 적용되지 않습니다.

   현재 각 파일의 allowlist 범위:

   | 디렉터리 | allowlist 범위 |
   |---|---|
   | `ai/.claude` | `settings.json`, `agents/`, `commands/`, `hooks/`, `skills/`, `scripts/`, `output-styles/`, `plugins/config.json` |
   | `ai/.hermes` | `config.yaml`, `SOUL.md`, `.env`, `bin/gateway-*`, `scripts/` 3개 파일(이름 지정), `profiles/*/{.env,config.yaml,SOUL.md}` |
   | `ai/.codex` | `config.toml`, `local.config.toml.example`, `codex-profile-check` |

   `ai/.codex`는 세 파일만 허용합니다. `skills/`, `scripts/`, `docs/`, `AGENTS.md`, `.github/`에 추가하는 파일은 모두 규칙을 넣어야 합니다.

   `ai/.hermes/scripts/`는 이름으로 세 파일만 허용합니다. 새 스크립트마다 `!scripts/<name>` 줄이 필요합니다.

3. 무시되지 않는지 다시 확인하고 stage합니다.

   ```zsh
   git -C ~/dotfiles check-ignore -v ai/.codex/skills/myskill/SKILL.md   # 출력 없어야 함
   git -C ~/dotfiles add ai/.codex/.gitignore ai/.codex/skills/myskill/SKILL.md
   git -C ~/dotfiles status --short ai/
   ```

4. credential이나 machine-local 상태를 추가하지 않았는지 확인합니다.

   ```zsh
   git -C ~/dotfiles diff --cached --stat
   git -C ~/dotfiles diff --cached | grep -iE 'token|secret|api[_-]?key|password'
   ```

### Verification

`git add` 이후 실제로 stage되었는지 확인합니다. `add`는 무시된 파일에 대해 조용히 아무 것도 하지 않습니다.

```zsh
git -C ~/dotfiles ls-files --error-unmatch ai/.codex/skills/myskill/SKILL.md
```

파일 이름을 출력하면 성공, `did not match any file(s) known to git`이면 여전히 무시되는 상태입니다.

### Troubleshooting

**`git add`가 아무 반응이 없다.** 무시되는 파일입니다. `check-ignore -v`로 원인 줄을 찾습니다. `git add -f`로 강제 추가할 수 있지만, `.gitignore`를 고치지 않으면 다음 파일에서 같은 일이 반복됩니다.

**`.gitignore`를 고쳤는데 여전히 무시된다.** 중간 디렉터리 규칙(`!dir/**/`)이 빠졌을 가능성이 큽니다. `check-ignore -v`가 알려주는 줄 번호를 확인합니다.

**추적하면 안 되는 파일이 stage되었다.** allowlist를 너무 넓게 열었습니다.

```zsh
git -C ~/dotfiles restore --staged <path>
```

---

## 새 Hermes profile 추가

전용 도구가 key 파일, 환경변수 배선, wrapper, LaunchAgent를 한 번에 처리합니다. 손으로 만들지 않습니다.

### Steps

1. 계획을 확인합니다.

   ```zsh
   ~/.hermes/scripts/gateway-management-profile --dry-run
   ```

2. 실제로 실행합니다. `1`(Create)을 선택합니다.

   ```zsh
   ~/.hermes/scripts/gateway-management-profile
   ```

   - 복제할 기존 profile을 고르거나 `0`으로 새로 만듭니다. 복제하면 `command_allowlist`까지 함께 복사됩니다.
   - 에이전트 이름은 `^[a-z0-9][a-z0-9-]*$`를 만족해야 합니다.
   - Discord bot token은 화면에 표시되지 않습니다.

3. **`command_allowlist`를 검토합니다.** 여기 나열된 작업은 확인 없이 실행됩니다.

   ```zsh
   $EDITOR ~/dotfiles/ai/.hermes/profiles/<name>/config.yaml
   ```

   복제한 profile의 allowlist를 그대로 물려받았을 수 있습니다. `recursive delete`, `execute_code`, `pipe decoded content to shell` 같은 항목이 필요한지 판단합니다.

4. `.env`가 값이 아니라 참조를 담고 있는지 확인합니다.

   ```zsh
   grep DISCORD ~/dotfiles/ai/.hermes/profiles/<name>/.env
   ```

   `DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN_<NAME>}` 형태여야 합니다. 실제 토큰 문자열이 보이면 커밋하지 않고 참조로 바꿉니다.

5. 연결을 확인합니다.

   ```zsh
   ~/.hermes/scripts/gateway-restart --all
   ```

6. 추적 상태를 확인하고 커밋합니다.

   ```zsh
   git -C ~/dotfiles status --short ai/.hermes
   ```

   `profiles/<name>/{.env,config.yaml,SOUL.md}`와 `bin/gateway-<name>`이 나타나야 합니다. wrapper가 보이지 않으면 이름이 `gateway-*` 패턴을 벗어났는지 확인합니다.

### Verification

```zsh
hermes gateway list
launchctl list | grep ai.hermes.gateway-<name>
ls -l ~/.hermes/bin/gateway-<name>      # 700 이어야 함
grep -c '/Users/' ~/.hermes/bin/gateway-<name>   # 0 이어야 함 ($HOME 사용)
```

### Troubleshooting

**gateway가 뜨지 않는다.** wrapper는 토큰이 없으면 조용히 종료합니다. secret이 동기화되었는지 확인합니다.

```zsh
~/.hermes/scripts/sync-secrets
grep -c DISCORD_BOT_TOKEN ~/.hermes/.launchd.env
```

**연결 검증이 실패로 보고된다.** `gateway-restart`는 `rg`로 로그를 확인합니다. `rg`가 없으면 재시작은 되지만 검증이 항상 실패합니다.

```zsh
command -v rg || brew install ripgrep
tail -n 120 ~/.hermes/profiles/<name>/logs/gateway.log
```

**LaunchAgent가 잘못된 파일을 실행한다.** wrapper를 재생성합니다.

```zsh
~/.hermes/scripts/gateway-management-profile --repair <name>
```

---

## 새 터미널/에디터 설정 추가

### Steps

1. `util/<tool>/` 아래에 설정 파일을 둡니다.
2. `scripts/bootstrap.sh`의 `run_shell_stage`에 `link_path` 줄을 추가합니다.

   ```zsh
   link_path "$DOTFILES_DIR/util/mytool/config" "$HOME/.config/mytool/config"
   ```

3. dry-run으로 확인합니다.

   ```zsh
   bash ~/dotfiles/scripts/bootstrap.sh --dry-run --shell-only
   ```

4. 실행하고 symlink를 확인합니다.

   ```zsh
   bash ~/dotfiles/scripts/bootstrap.sh --shell-only
   readlink ~/.config/mytool/config
   ```

기존 파일이 있으면 backup으로 이동합니다. 현재 구현은 첫 backup을 홈 디렉터리에 만듭니다. 두 위치를 모두 확인합니다.

```zsh
ls -d ~/*.bak.* 2>/dev/null
ls -A ~/.dotfiles-backup
```

[Bootstrap CLI reference](reference-bootstrap-cli.md)의 Backup 경로 절을 참고합니다.

### Verification

```zsh
bash scripts/tests/bootstrap-rerun-test.sh
bash scripts/tests/bootstrap-matrix-test.sh
```

---

## 변경 후 공통 체크리스트

```zsh
# 셸이 오류 없이 시작하는지
zsh -i -c exit

# startup 시간이 유지되는지
time zsh -i -c exit

# zsh 회귀 테스트
for t in zsh/tests/*.zsh; do zsh "$t" || echo "FAIL: $t"; done

# bootstrap 회귀 테스트
for t in scripts/tests/*.sh; do bash "$t" || echo "FAIL: $t"; done

# 의도한 파일만 stage되었는지
git status --short
git diff --cached --stat
```

문서도 함께 갱신합니다.

| 추가한 것 | 갱신할 문서 |
|---|---|
| alias 또는 함수 | [Shell command reference](reference-shell-commands.md) |
| bootstrap flag 또는 링크 대상 | [Bootstrap CLI reference](reference-bootstrap-cli.md) |
| Hermes profile 또는 gateway | [Hermes gateway reference](reference-hermes-gateways.md) |
| 디렉터리 또는 소유 경계 | [Project structure reference](project-structure.md) |
| 장기적으로 되돌리기 어려운 결정 | [decisions.md](decisions.md) |

## Related

- [Bootstrap How-to](howto-bootstrap.md): 설치와 재실행 절차
- [Project structure reference](project-structure.md): 디렉터리 소유 경계
- [Secret handling](explanation-secret-handling.md): allowlist gitignore를 쓰는 이유
- [구조 검토](review-structural-2026-08-26.md): 이 문서가 우회 절차를 안내하는 알려진 문제
