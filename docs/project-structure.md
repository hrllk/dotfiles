# Project structure reference

이 문서는 저장소의 **활성 설정**, **배포 스크립트**, **문서·계획**, **역사적 보관 영역**을 구분해 설명합니다. 이 저장소는 실행 애플리케이션이 아니라 macOS 개발환경의 설정을 관리합니다.

실제 셸 진입점은 `~/.zshrc`에서 저장소의 `zsh/.zshrc`를 가리키는 구조입니다. 전체 설치 흐름은 [Bootstrap How-to](howto-bootstrap.md), 초기화 책임은 [Configuration architecture](explanation-architecture.md)를 참고합니다.

## Repository boundaries

```text
.
├── ai/                 AI 도구별 설정과 운영 스크립트
├── archive/            현재 사용하지 않는 과거 설정 보관
├── docs/               설치·구조·설계·검증 문서
├── scripts/            저장소 bootstrap과 회귀 테스트
├── util/               terminal, tmux, editor 설정과 정적 자산
├── zsh/                실제 zsh 초기화와 모듈
├── .taskmaster/        작업 목록과 planning metadata
├── README.md           저장소 개요와 빠른 시작
└── package.json        Yarn 버전 metadata
```

### Active configuration

`ai/`, `util/`, `zsh/`와 `scripts/bootstrap.sh`가 현재 설정과 배포 흐름을 구성합니다. `archive/`는 active source가 아닙니다.

### Runtime state

AI 도구의 로그, cache, database, heartbeat, session 파일은 설정 source와 다릅니다. 이런 runtime state는 문서의 구조 예시에 포함하지 않습니다. secret 값과 runtime database도 프로젝트 구조의 공개 API가 아닙니다.

## AI configuration domains

```text
ai/
├── .claude/
│   ├── settings.json             Claude Code 설정
│   └── scripts/link-claude-home  Claude home 연결과 backup
├── .codex/
│   ├── config.toml                Codex 기본 설정
│   ├── AGENTS.md                  Codex harness 운영 규칙
│   ├── hooks.json                 tmux notification hook 설정
│   ├── init-home-codex            local Codex home 초기화 진입점
│   ├── scripts/                   bootstrap, check, test, doctor 등
│   └── local.config.toml.example  machine-local 설정 예시
└── .hermes/
    ├── config.yaml                Hermes 공통 설정
    ├── bin/                       profile별 gateway 진입점
    ├── scripts/                   gateway 관리와 secret sync
    └── README.md                  Hermes 운영 안내
```

AI 영역은 도구별 책임을 분리합니다.

| 영역 | 소유 책임 | 배포 방식 |
|---|---|---|
| `ai/.claude` | Claude 설정과 Claude home backup/link | bootstrap의 `--ai` 단계 |
| `ai/.codex` | Codex harness, hooks, profile 정책 | `init-home-codex` 등 명시적 local setup |
| `ai/.hermes` | Hermes profile/gateway 설정과 runtime sync script | bootstrap의 `--ai`, sync는 별도 `--sync-secrets` |

`bootstrap.sh`는 Codex profile을 자동 복사하거나 symlink하지 않습니다. Codex local profile이 필요하면 `ai/.codex/init-home-codex`의 명시적 절차를 사용합니다.

## zsh layout

```text
zsh/
├── .zshrc                         startup orchestration
├── .p10k.zsh                      Powerlevel10k prompt 설정
├── env.zsh                        공통 환경변수와 tool home
├── path.zsh                       PATH/path mutation 단일 소유자
├── options/
│   ├── completion.zsh             completion 초기화
│   ├── history.zsh                history 정책
│   └── keybindings.zsh            vi mode와 키 바인딩
├── integrations/
│   ├── rbenv.zsh                  rbenv shim 경로 계산
│   ├── bun.zsh                    Bun bin 경로 계산
│   └── lazy/
│       ├── nvm.zsh                nvm lazy loader
│       ├── node-commands.zsh      Node command fallback wrapper
│       └── sdkman.zsh              SDKMAN lazy entrypoint
├── aliases/                       navigation, git, tools, taskmaster, work
├── plugins/                       custom plugin과 OMZ plugin 조합
├── secrets/                       domain별 secret export
└── tests/                         zsh ownership/startup/SDKMAN 회귀 테스트
```

`.zshrc`는 조합기입니다. 각 모듈의 책임은 다음과 같습니다.

| 모듈 | 하는 일 | 하지 않는 일 |
|---|---|---|
| `env.zsh` | 공통 환경변수와 tool home 설정 | PATH 변경, runtime sync |
| `path.zsh` | `path` 배열과 `PATH` 정규화·등록 | secret 로드, plugin 초기화 |
| `integrations/` | 외부 도구의 경로값·hook 계산 | 직접적인 PATH mutation |
| `integrations/lazy/` | 실제 사용 시 외부 도구 초기화 | startup에서 모든 도구 eager 초기화 |
| `secrets/` | local secret file을 환경변수로 export | secret 값 저장소 기록, Hermes runtime sync |
| `aliases/` | 사용자 명령 alias와 함수 | plugin 설치 |
| `plugins/` | plugin/theme 설정 | secret 동기화 |

## Deployment and bootstrap

[`scripts/bootstrap.sh`](../scripts/bootstrap.sh)는 설치 단계를 두 영역으로 나눕니다.

| Stage | 명령 | 책임 | 주요 대상 |
|---|---|---|---|
| shell/terminal | `--shell-only` 또는 인자 없음 | plugin clone, backup, symlink | `~/.zshrc`, tmux, Kitty, WezTerm, JetBrains |
| AI | `--ai` | Claude/Hermes 연결과 Codex 안내 | `~/.claude`, `~/.hermes` |
| runtime sync | `--ai --sync-secrets` | Hermes runtime secret file 생성 | Hermes launch/runtime 환경 |
| preview | `--dry-run` 조합 | 계획 출력만 수행 | filesystem/network 변경 없음 |

공통 dispatcher가 flag 조합을 먼저 검증합니다. `--ai`와 `--shell-only`를 함께 사용할 수 없고, `--sync-secrets`는 `--ai`와 함께 사용해야 합니다. invalid 조합은 stage를 실행하지 않고 exit `2`로 종료합니다.

백업 timestamp는 invocation 전체에서 하나를 공유합니다. `BACKUP_TIMESTAMP`를 지정하지 않으면 bootstrap 시작 시 생성하고, 기존 backup과 충돌하면 `.1`, `.2` suffix를 사용합니다.

지원하는 주요 환경변수:

| 변수 | 기본값 | 역할 |
|---|---|---|
| `DOTFILES_DIR` | `$HOME/dotfiles` | source repository 위치 |
| `ZSH_CUSTOM_DIR` | `$HOME/.oh-my-zsh/custom` | zsh plugin 설치 위치 |
| `BACKUP_ROOT` | `$HOME/.dotfiles-backup` | backup root |
| `BACKUP_TIMESTAMP` | invocation 시작 시 생성 | backup timestamp 고정 |

자세한 명령과 재실행 절차는 [Bootstrap How-to](howto-bootstrap.md)를 참고합니다.

## util layout

```text
util/
├── jetbrains/.ideavimrc            JetBrains Vim 설정
├── kitty/kitty.conf                Kitty 설정
├── wezterm/wezterm.lua             WezTerm 설정
├── tmux/
│   ├── .tmux.conf                  tmux 기본 설정
│   ├── .gitmux.conf                Git 상태 표시 설정
│   └── .tmux/scripts/              상태바 보조 script
└── assets/wallpapers/              terminal이 참조하는 정적 이미지
```

외부 plugin과 TPM은 repository에 저장하지 않고 bootstrap이 사용자 home 아래에 설치합니다.

## Documentation, planning, and tests

```text
docs/
├── index.md                        문서 진입점
├── tutorial-first-setup.md         새 환경 설치 Tutorial
├── howto-bootstrap.md              bootstrap How-to
├── project-structure.md            현재 문서
├── explanation-architecture.md     startup과 책임 경계 Explanation
├── design-*.md                     Codex/tmux 설계 문서
└── decisions.md                    장기 설정 결정 기록

scripts/tests/
├── baseline-smoke-test.sh          refactor 전 기준 생성·보존
├── post-refactor-smoke-test.sh     현재 계약 통합 검증
├── bootstrap-*.sh                   mode, rerun, timestamp 검증
├── claude-backup-contract-test.sh  Claude backup contract
└── sync-contract-test.sh           Hermes sync redaction contract

.taskmaster/
├── tasks/tasks.json                작업 상태와 dependency graph
├── config.json                     Task Master 설정
└── state.json                      현재 tag와 CLI 상태
```

## Active, runtime-only, and historical files

| 구분 | 예시 | 문서화 원칙 |
|---|---|---|
| active source | `zsh/`, `util/`, `ai/.codex/`, `ai/.claude/`, `scripts/` | public responsibility와 배포 경로를 기록 |
| runtime-only | Hermes logs/cache/db, Codex sessions, gateway heartbeat | 구조 예시에서 제외하고 secret·session 내용을 기록하지 않음 |
| historical | `archive/`, `README.md.bak` | active 설정으로 설명하지 않음 |
| machine-local | `local.config.toml`, local secret files, home symlink | 예시와 생성 절차만 문서화하고 값을 저장소에 기록하지 않음 |

새 설정을 추가할 때는 먼저 소유 영역을 정하고, active source와 runtime output을 같은 디렉터리에 섞지 않는 것을 원칙으로 합니다.
