# Shell command reference

이 문서는 셸을 시작한 뒤 **사용자가 직접 입력하는 명령**을 모두 나열합니다. alias, 함수, lazy wrapper, secret loader가 대상입니다. 내부 helper(`__`, `_` 접두사)는 직접 호출용이 아니지만 동작을 이해하는 데 필요한 범위에서 함께 설명합니다.

각 명령의 정의 위치는 `zsh/` 아래 모듈입니다. 로드 순서는 [Configuration architecture](explanation-architecture.md), 소유 경계는 [Project structure reference](project-structure.md)를 참고합니다.

## Task Master

`zsh/aliases/taskmaster.zsh`. Powerlevel10k instant prompt 직후에 가장 먼저 로드됩니다.

| 명령 | 정의 | 대상 |
|---|---|---|
| `tm` | alias | `task-master` |
| `taskmaster` | alias | `task-master` |
| `hamster` | alias | `task-master` |
| `ham` | alias | `task-master` |

네 alias 모두 같은 `task-master`를 가리킵니다. `task-master` 자체는 `zsh/integrations/lazy/node-commands.zsh`의 lazy wrapper 함수이므로, 실제 실행 경로는 아래 [Lazy tool loaders](#lazy-tool-loaders)를 따릅니다.

## Navigation

`zsh/aliases/navigation.zsh`.

| 명령 | 정의 | 동작 |
|---|---|---|
| `todo` | alias | `$HOME/task/sources/personal/secretary`로 이동한 뒤 `nvim` 실행 |
| `cdsource` | alias | `$HOME/task/sources`로 이동 |
| `cdtask` | alias | iCloud Drive의 `task` 디렉터리로 이동 |
| `ll` | alias | `colorls`가 있으면 `colorls -lGt --gs --sd`, 없으면 `ls -lG` |
| `ls` | alias | `colorls`가 있을 때만 `colorls`로 대체. 없으면 시스템 `ls` 유지 |
| `tree` | function | 깊이 제한 트리 출력 |

### `tree [depth] [mode]`

```zsh
tree          # 깊이 1, 파일과 디렉터리 모두
tree 3        # 깊이 3
tree 2 dirs   # 깊이 2, 디렉터리만 (colorls가 있을 때만 유효)
```

| 인자 | 기본값 | 값 |
|---|---|---|
| `depth` | `1` | 트리 깊이 |
| `mode` | `all` | `all` 또는 `dirs` |

구현체는 세 단계로 fallback합니다.

```text
colorls 있음  -> colorls -l --tree=<depth> (--dirs 또는 --sd --sf)
colorls 없음, tree 있음 -> command tree -L <depth>
둘 다 없음    -> command ls -la
```

이 함수는 시스템 `tree` 실행 파일을 가립니다. 원본이 필요하면 `command tree`를 사용합니다.

> 현재 구현은 대상 디렉터리를 인자로 받지 않습니다. 내부에서 `${dir:-.}`를 참조하지만 `dir`은 어디에서도 대입되지 않으므로 항상 현재 디렉터리를 대상으로 합니다. 상세는 [구조 검토](review-structural-2026-08-26.md)의 S-08 항목을 참고합니다.

## Git

`zsh/aliases/git.zsh`. 27개 alias 전부 `GIT_TRACE=1`을 붙여 실행합니다. 즉 **모든 git alias는 trace 로그를 stderr로 출력합니다.**

| 명령 | 실행 |
|---|---|
| `gs` | `git status -sb` |
| `gst` | `git status` |
| `ga` | `git add` |
| `gaa` | `git add .` |
| `gb` | `git branch` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gca` | `git commit --amend` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gm` | `git merge` |
| `grb` | `git rebase` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gr` | `git restore` |
| `grs` | `git reset` |
| `grh` | `git reset --hard` |
| `gt` | `git tag` |
| `gstash` | `git stash` |
| `gsta` | `git stash apply` |
| `gpop` | `git stash pop` |
| `gclean` | `git clean -fd` |
| `glgc` | `git log --oneline --graph --decorate` |
| `glga` | `git log --graph --decorate --all --format=...` (유일하게 `GIT_TRACE` 없음) |

네트워크 명령은 추가 trace 변수를 켭니다.

| 명령 | 실행 | 추가 환경변수 |
|---|---|---|
| `gp` | `git push` | `GIT_TRACE_PACKET=1`, `GIT_TRACE_PERFORMANCE=1` |
| `gpf` | `git push -f` | `GIT_TRACE_PACKET=1`, `GIT_TRACE_PERFORMANCE=1` |
| `gl` | `git pull --rebase` | `GIT_TRACE_PACKET=1`, `GIT_CURL_VERBOSE=1` |

> `gl`의 `GIT_CURL_VERBOSE=1`은 HTTP 요청 헤더를 stderr로 출력합니다. HTTPS remote에서 credential helper를 사용하면 `Authorization` 헤더가 터미널 스크롤백과 로그에 남을 수 있습니다. 상세는 [구조 검토](review-structural-2026-08-26.md)의 S-03 항목을 참고합니다.

`grh`(`reset --hard`)와 `gclean`(`clean -fd`)은 확인 절차 없이 즉시 파괴적으로 동작합니다.

## Tools and shortcuts

`zsh/aliases/tools.zsh`, `zsh/aliases/others.zsh`.

| 명령 | 실행 |
|---|---|
| `vi` | `nvim` |
| `k` | `kubectl` |
| `hgrep <pattern>` | `history \| grep <pattern>` |
| `cl` | `clear` |

## Work: datacenter SSH

`zsh/aliases/work.zsh`. 세 함수가 사내 데이터센터 호스트에 root 비밀번호 인증으로 접속합니다.

| 명령 | 대상 환경 | 비밀번호 변수 |
|---|---|---|
| `godcprd` | production | `DC_TRB_PRD` |
| `godcstg` | staging | `DC_TRB_STG` |
| `godcdev` | development | `DC_TRB_DEV` |

각 함수의 실행 순서:

1. `load_oke_vars`로 비밀번호 세 개를 로컬 key 파일에서 export
2. `ssh-keygen -F <host>`로 host key가 `known_hosts`에 있는지 확인. 없으면 exit `6`과 안내 출력
3. `sshpass` 실행 파일 해석. `command -v` 실패 시 `brew --prefix sshpass`로 재시도, 둘 다 실패하면 exit `127`
4. `sshpass ... ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@<host>`

| 종료 코드 | 의미 |
|---|---|
| `6` | host key가 `known_hosts`에 없음. `ssh root@<host>`를 한 번 실행해 fingerprint 확인 후 재시도 |
| `127` | `sshpass` 미설치. `brew install sshpass` |
| 기타 | `load_oke_vars` 또는 `ssh` 자체의 종료 코드 |

> 이 파일은 사내 호스트 IP와 root 비밀번호 인증 절차를 저장소에 직접 기록합니다. 저장소가 공개 상태라면 노출 범위를 먼저 검토해야 합니다. 상세는 [구조 검토](review-structural-2026-08-26.md)의 S-01 항목을 참고합니다.

## Codex wrapper

`zsh/aliases/codex.zsh`. `codex` 함수가 실행 파일을 감싸 **local profile 사용을 강제**합니다.

```text
codex <args>
  ├─ 인자에 -p/--profile 지정됨  -> command codex <args>            (그대로 통과)
  ├─ -p/--profile 값이 비어 있음 -> exit 2 + 오류 메시지
  └─ profile 미지정              -> local profile 검증 후
                                    command codex -p local <args>
```

profile 미지정 시 `_codex_require_local_profile`이 `${CODEX_HOME:-$HOME/.codex}/local.config.toml`을 다음 순서로 검사합니다.

| 검사 | 실패 시 메시지 |
|---|---|
| 파일 존재 | `Codex local profile is missing: local.config.toml` + example 경로 안내 |
| 소유자 == 현재 사용자 | `Codex local profile must be owned by the current user` |
| group/world write 비트 없음 | `Codex local profile must not be group/world-writable` + `chmod 600` 안내 |

| 종료 코드 | 의미 |
|---|---|
| `0` | 정상 실행 |
| `1` | local profile 누락 또는 권한 위반 |
| `2` | `-p`/`--profile` 뒤에 값이 없음 |

`--` 이후의 인자는 profile 탐색에서 제외됩니다. `-plocal`처럼 붙여 쓴 형태도 명시적 지정으로 인식합니다.

profile 파일은 저장소가 관리하지 않습니다. `ai/.codex/local.config.toml.example`을 복사해 직접 만듭니다.

## Lazy tool loaders

첫 호출 시점에 외부 도구를 초기화합니다. 셸 시작 시간을 유지하기 위한 구조이며, 모든 wrapper는 자신을 `unset -f`한 뒤 실제 도구로 위임합니다.

### Node 계열

`zsh/integrations/lazy/node-commands.zsh`가 네 개 wrapper를 정의합니다.

| 명령 |
|---|
| `npx` |
| `gemini` |
| `task-master` |
| `openclaw` |

공통 해석 순서(`__run_with_nvm`):

```text
1. command -v <cmd> 성공  -> 그대로 실행           (nvm 로드 안 함)
2. 실패                   -> __load_nvm
3. nvm 로드 실패          -> return 127
4. 여전히 없음            -> nvm use default, 실패하면 nvm use node
5. 그래도 없음            -> return 127
```

1번이 먼저인 이유는 Homebrew 등 nvm 밖에서 설치한 실행 파일을 우선 사용하기 위해서입니다.

### `nvm`

`zsh/integrations/lazy/nvm.zsh`. `NVM_DIR`은 `$HOME/.nvm`으로 고정 export됩니다. 로더 스크립트는 다음 순서로 탐색합니다.

```text
$NVM_DIR/nvm.sh
brew --prefix nvm 아래 nvm.sh
/opt/homebrew/opt/nvm/nvm.sh
/usr/local/opt/nvm/nvm.sh
```

로드에 성공하면 `nvm use default`, 실패 시 `nvm use node`를 조용히 시도하고 `__NVM_LOADED=1`을 설정합니다. 모두 실패하면 탐색 경로를 나열한 오류와 함께 `127`을 반환합니다.

### `sdk`

`zsh/integrations/lazy/sdkman.zsh`. `SDKMAN_DIR`은 `$HOME/.sdkman`으로 고정 export됩니다. `$SDKMAN_DIR/bin/sdkman-init.sh`가 없으면 오류 한 줄과 함께 `127`을 반환합니다.

> `sdk`와 `nvm` wrapper는 실패 경로에서도 자신을 먼저 `unset -f`합니다. 따라서 도구가 설치되지 않은 환경에서 진단 메시지는 **첫 호출에만** 표시되고, 두 번째 호출부터는 `command not found`가 됩니다. 상세는 [구조 검토](review-structural-2026-08-26.md)의 S-06 항목을 참고합니다.

## Secret loaders

`zsh/secrets/`. 값 자체는 저장소에 없고, `DOTFILES_KEY_DIR` 아래 로컬 파일에서 읽습니다. 기본값은 iCloud Drive의 `task/keys`입니다. 설계 배경은 [Secret handling](explanation-secret-handling.md)을 참고합니다.

| 명령 | 정의 | export하는 변수 |
|---|---|---|
| `load_ai_keys` | `secrets/ai.zsh` | `DEEPSEEK_API_KEY`, `CLAUDE_API_KEY`, `GEMINI_API_KEY`, `TAVILY_API_KEY`, `GIT_TOKEN` |
| `load_dns_keys` | `secrets/dns.zsh` | `CLOUD_FLARE_TOKEN`, `CLOUD_FLARE_ZONEID` |
| `load_work_keys` | `secrets/work.zsh` | `FIGMA_TOKEN`, `CONFLUENCE_TOKEN` |
| `load_oke_vars` | `secrets/work.zsh` | `DC_TRB_PRD`, `DC_TRB_STG`, `DC_TRB_DEV` |
| `load_all_keys` | `secrets/index.zsh` | 위 네 함수를 정의된 것만 순서대로 호출 |

startup에서 항상 설정되는 값:

| 변수 | 정의 | 값 |
|---|---|---|
| `DOTFILES_KEY_DIR` | `secrets/_shared.zsh` | key 파일 루트. 기본값은 iCloud `task/keys` |
| `OLLAMA_HOST` | `secrets/ai.zsh` | `0.0.0.0` |
| `SOPS_AGE_KEY_FILE` | `secrets/dns.zsh` | `$HOME/.config/sops/age/keys.txt` |

`secrets/personal.zsh`는 loader 함수 없이 startup에서 즉시 세 값을 export합니다.

| 변수 | key 파일 |
|---|---|
| `DISCORD_USER_ID_ALZAR` | `personal/discord/discord-user-id-alzar` |
| `DISCORD_BOT_TOKEN_GRAPHKEEPER` | `personal/discord/discord-bot-token-graphkeeper` |
| `DISCORD_BOT_TOKEN_DEFAULT` | `personal/discord/discord-bot-token-default` |

> `personal.zsh`만 eager 방식이라 key 파일이 없는 환경에서는 셸을 열 때마다 `secret file not readable`이 세 줄 출력됩니다. `load_all_keys`도 이 파일을 다루지 않습니다. 상세는 [구조 검토](review-structural-2026-08-26.md)의 S-07 항목을 참고합니다.

## Shell internals

직접 입력하는 명령은 아니지만 startup 동작을 이해하는 데 필요한 함수입니다.

| 함수 | 정의 | 역할 |
|---|---|---|
| `source_if_exists <path>` | `zsh/.zshrc` | 읽을 수 있는 파일만 source |
| `__export_secret <NAME> <path>` | `secrets/_shared.zsh` | 파일 첫 줄을 읽어 환경변수로 export. 읽기 실패 시 `secret file not readable`과 함께 `1` 반환 |
| `bind_completion_keys` | `options/keybindings.zsh` | Shift-Tab을 `reverse-menu-complete`에 바인딩. `precmd` hook으로 매 프롬프트마다 재적용 |
| `reload_zshrc` | `zsh/.zshrc` | `ZSH_AUTO_RELOAD=1`일 때만 등록. `.zshrc`/`.p10k.zsh` mtime 변경 시 재로드 |
| `prompt_context` | `plugins/omz/theme.zsh` | 빈 함수로 정의해 기본 prompt context 표시를 제거 |

## Key bindings

`zsh/options/keybindings.zsh`가 `vi` 모드를 켭니다(`set -o vi`).

| 키 | 동작 | 적용 keymap |
|---|---|---|
| Shift-Tab | `reverse-menu-complete` | `viins`, `vicmd`, `emacs`, `menuselect`, 기본 |
| Backspace (`^?`, `^H`) | `vi-backward-delete-char` | `viins`, `vicmd` |
| Backspace (`^?`, `^H`) | `backward-delete-char` | `emacs` |
| Tab | `fzf-tab-complete` (fzf 설치 시) 또는 `expand-or-complete` | 기본 |
| `/` | fzf-tab continuous-trigger. 다음 경로 후보로 이어서 이동 | fzf-tab 활성 시 |
| `<`, `>` | fzf-tab group 전환 | fzf-tab 활성 시 |

`zsh/plugins/custom/safe-paste.zsh`는 bracketed paste를 유지합니다. 여러 줄 붙여넣기는 줄 구조를 보존하고, CRLF와 CR는 LF로 정규화합니다. zsh 5.1 미만에서는 아무 것도 하지 않습니다. 배경은 [decisions.md](decisions.md)에 있습니다.

## Verification

명령 표면이 정상 로드되었는지 확인합니다.

```zsh
type tm task-master codex sdk nvm tree
type -f load_all_keys load_ai_keys load_oke_vars
alias | grep -c GIT_TRACE      # 26
bindkey -M viins '^I'
time zsh -i -c exit
```

`type`이 alias 또는 function을 보고해야 합니다. `command not found`가 나오면 해당 모듈이 로드되지 않았으므로 [Bootstrap How-to](howto-bootstrap.md)의 symlink 확인 절차를 사용합니다.

## Related

- [Bootstrap CLI reference](reference-bootstrap-cli.md): 설치 스크립트의 flag, 환경변수, 종료 코드
- [Secret handling](explanation-secret-handling.md): key 파일과 환경변수 사이의 간접 계층
- [Configuration architecture](explanation-architecture.md): 모듈 로드 순서와 책임 경계
- [Project structure reference](project-structure.md): 디렉터리 소유 경계
- [구조 검토](review-structural-2026-08-26.md): 이 문서가 참조하는 알려진 문제 목록
