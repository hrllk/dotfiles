<!-- /autoplan restore point: /Users/hrk/.gstack/projects/hrllk-dotfiles/main-autoplan-restore-20260827-111727.md -->
# Design: Bootstrap를 개별 실행 가능한 단위로 분리

## 문제

`scripts/bootstrap.sh`는 두 개의 배타적 모드(`--shell-only`, `--ai`)만 제공한다.
한 번 실행으로는 전체 설정이 절대 완성되지 않으며, 어떤 단위가 반영되고 어떤 단위가
빠졌는지 확인할 방법이 없다. 설치 헬퍼는 `scripts/`와 `ai/*/` 아래로 흩어져 있고,
같은 이름의 함수가 두 벌 존재해 이미 한쪽이 버그를 갖고 갈라졌다.

## 배경 사실 (실측)

샌드박스에서 격리된 `HOME`으로 실제 실행해 확인했다.

| 시나리오 | 결과 |
|---|---|
| 동일 조건 2회 실행 | 상태 변화 0, 백업 0. 멱등 |
| 링크 삭제 후 재실행 | 복구됨 |
| 링크가 일반 파일로 교체됨 | 백업 후 재링크 |
| dotfiles 경로가 사라진 깨진 심링크 | 복구됨 |
| `--ai` 실행 후 `~/.codex` | 생성되지 않음 |
| 중단된 clone(`.git`만 존재) 재실행 | 재clone 0회, 깨진 채 방치 |
| 백업 위치 | 첫 백업은 `$HOME`, 충돌 시에만 `BACKUP_ROOT` |

즉 링크 계층은 이미 멱등하다. 문제는 단위 구성과 커버리지다.

## 확인된 구멍

- **G1** 전체 설치 모드가 없다. `--ai`와 `--shell-only`가 배타적이다(`bootstrap.sh:74-83`).
- **G2** `~/.codex`를 bootstrap이 만들지 않는다. `run_ai_stage`(`bootstrap.sh:195-204`)가
  `ai/.codex/init-home-codex`를 호출하지 않고 안내 문장만 출력한다.
- **G3** 실제 파일시스템을 건드리는 경로에 테스트가 하나도 없다. 기존 두 테스트는
  `--dry-run`과 인자검증만 본다.
- **G4** `backup_path_for`(`bootstrap.sh:106-117`)의 첫 후보가 `$HOME`이다. 완료 메시지는
  `BACKUP_ROOT`를 출력해 실제와 다르다. 같은 함수가 `ai/.claude/scripts/link-claude-home:63-74`
  에는 올바르게 구현되어 있다. 구조검토 S-04와 동일 건.
- **G5** `clone_if_missing`(`bootstrap.sh:147`)이 `[[ -d "$target/.git" ]]`만 본다.
  중단된 clone이 영구히 복구되지 않는다.

추가로 커밋 `aa4b8ff`가 stage 간 의존성을 새로 만들었다. Codex hook이
`$HOME/.tmux/scripts/ai-notify-hook.sh`를 참조하는데 `~/.tmux`는 shell 단계가 링크한다.
`--ai`만 실행한 기기에서는 hook이 파일 없음으로 실패한다.

## 목표

1. 각 설정 단위를 독립적으로 실행할 수 있다.
2. 한 명령으로 전체를 설치할 수 있다.
3. 변경 없이 현재 반영 상태를 확인할 수 있고, 미반영이 있으면 비정상 종료 코드를 낸다.
4. 재실행과 부분 반영 상태에서 기존 기능을 망가뜨리지 않는다.
5. 위 동작이 자동 테스트로 검증된다.

## 비목표

- 기존 플러그인 clone의 자동 업데이트. 현재는 최초 clone 버전을 고정한다. 재현성
  측면에서 의도된 동작일 수 있어 별도 판단이 필요하다.
- `~/.oh-my-zsh` 본체 설치. 현재 `custom/` 하위만 만들고 본체는 설치하지 않는다.
- 구조검토 S-01(공개 저장소 노출)을 포함한 다른 등급 항목.

## 스크립트 소유권 분류

`ai/` 아래 스크립트는 세 부류로 갈리며, 이동 대상은 A뿐이다.

**A. dotfiles 소유 설치 헬퍼 — `scripts/`로 이동**
- `ai/.claude/scripts/link-claude-home`: bootstrap만 호출한다. 현재 위치 탓에
  `~/.claude/scripts/`로도 배포되어 Claude 런타임 표면을 오염시킨다.
- `ai/.hermes/scripts/sync-secrets`: 성격이 같다. 설치 시점 1회 작업이다.

**B. 배포 표면에 있어야 하는 런타임 도구 — 이동하지 않음**
- `ai/.codex/codex-profile-check`: `zsh/aliases/codex.zsh:11-15`가 매 실행마다 호출한다.
- `ai/.hermes/scripts/gateway-restart`, `gateway-management-profile`: 운영 중 사용한다.

**C. upstream harness 소유 — 이동하지 않음**
- `ai/.codex/scripts/{bootstrap,check,test,eval,doctor,hooks}`: `harness.yml`이 선언한
  `harness-for-codex` 템플릿 자산이다.

`ai/.codex/init-home-codex`는 커밋 `ba37607`이 harness root로 의도적으로 옮긴 파일이며,
자기 위치(`$(dirname "${BASH_SOURCE[0]}")`)를 링크 대상으로 삼는다. 위치가 곧 로직이다.

## 제안 구조

```
scripts/
  bootstrap                  오케스트레이터
  bootstrap.d/
    lib.sh                   link_path, backup_path_for, clone_if_missing, run_command
    10-shell.sh              zsh 플러그인 clone + .zshrc
    20-terminal.sh           tmux, .tmux, kitty, wezterm, ideavim
    30-claude.sh             link-claude-home 흡수
    40-codex.sh              init-home-codex 호출
    50-hermes.sh             ~/.hermes
    60-secrets.sh            sync-secrets 흡수
  tests/
```

각 단위는 함수 3개 계약을 구현한다.

| 함수 | 역할 | 종료 코드 |
|---|---|---|
| `unit_preflight` | 전제조건과 의존 단위 확인 | 0 통과 / 10 미충족 |
| `unit_check` | 변경 없이 상태 보고 | 0 동기화됨 / 1 미반영 |
| `unit_apply` | 실제 적용 | 0 성공 / 20 실패 |

CLI:

```
bootstrap --list
bootstrap --all
bootstrap shell terminal
bootstrap --check
bootstrap --dry-run --all
```

`--shell-only`, `--ai`, `--sync-secrets`는 단위 조합 alias로 유지해 하위호환을 지킨다.

## 구멍과의 대응

| 구멍 | 닫는 방법 |
|---|---|
| G1 전체 설치 모드 없음 | `--all` |
| G2 `~/.codex` 미연결 | `40-codex.sh`가 단위로 존재 |
| G3 실행 테스트 0개 | 단위별 `check`/`apply` 계약 테스트 |
| G4 백업이 `$HOME`으로 샘 | `backup_path_for`가 `lib.sh` 한 벌만 존재 |
| G5 중단된 clone 방치 | `git -C "$target" rev-parse --verify HEAD` 검증 |
| aa4b8ff stage 간 의존 | `40-codex.sh`의 `unit_preflight`가 terminal 의존 선언 |

## 작업 순서

1. **`scripts/tests/bootstrap-idempotency-test.sh` 신설.** 격리된 `HOME`과 git stub으로
   실제 실행한다. 2회 연속 무변화, 링크 삭제 복구, 일반파일 교체 복구, 깨진 심링크 복구,
   중단된 clone 복구, 백업 위치 단일성을 검증한다. `post-refactor-smoke-test.sh`에 연결한다.
   구조검토 S-28도 함께 닫힌다.
2. **`lib.sh` 추출과 단위 분리.** 동작은 그대로 두고 구조만 바꾼다. 1단계 테스트 통과가
   성공 기준이다.
3. **누락 단위 추가와 CLI 확장.** `40-codex.sh`, `--check`, `--all`, `--list`.
4. **A그룹 스크립트 이동과 문서 갱신.** `reference-bootstrap-cli.md`,
   `project-structure.md`, `tutorial-first-setup.md`, `README.md`.

2단계가 가장 크다. 1단계 없이 2단계에 들어가면 회귀를 잡을 방법이 없다.

## 미해결 질문

- `ai/.codex/init-home-codex`를 `scripts/`로 옮길 것인가. 현재 제안은 `40-codex.sh`가
  얇게 호출만 하고 파일은 harness root에 남기는 쪽이다. `ba37607`의 결정을 뒤집지 않고
  수동 실행 경로(`docs/tutorial-first-setup.md:69`)도 유지된다.
- `ai/.hermes/scripts/sync-secrets`를 옮길 것인가. A그룹 성격이지만 hermes 운영 중에도
  호출할 수 있다. 옮기면 `~/.hermes/scripts/`에서 사라진다.
- `bootstrap.sh`를 `bootstrap`으로 개명할 것인가. `ai/.codex/scripts/`는 확장자를 쓰지 않는다.

---

# CEO REVIEW (Phase 1)

Mode: SELECTIVE EXPANSION. Outside voices: Codex disabled by config, Claude subagent only.

## 0A. Premise Challenge

플랜이 깔고 있는 전제 5개를 각각 검증했다.

**P1. "재실행·부분반영 안전성이 해결해야 할 문제다" — 부분적으로 틀렸다.**
격리된 `HOME`에서 실측한 결과 링크 계층은 이미 멱등하다. 2회 연속 실행 무변화, 링크 삭제 복구,
일반파일 교체 복구, 깨진 심링크 복구가 전부 통과한다. 실제로 아픈 곳은 재실행이 아니라
**1회 실행이 완결되지 않는다**는 점이다. `--ai`를 돌려도 `~/.codex`가 안 생기고(G2),
전체를 깔려면 두 번 호출해야 한다(G1). 문제의 이름은 "멱등성"이 아니라 "1회 실행 완결성"이다.
이 교정은 우선순위를 바꾼다. G1·G2가 먼저고 G4·G5는 위생 작업이다.

**P2. "단위로 찢어야 한다" — 조건부로 맞다.**
231줄 스크립트를 7개 파일로 나누는 것 자체는 이득이 아니다. 이득은 `unit_check` 계약이
`--check`를 가능하게 한다는 점이고, 그게 "지금 뭐가 반영돼 있나"를 답한다. 단위 분리는
수단이지 목적이 아니다. 이 구분을 놓치면 파일 개수만 늘어난다.

**P3. "설치 스크립트를 `scripts/` 한곳에 모아야 한다" — 원래 형태로는 틀렸고, 플랜이 이미 교정했다.**
A/B/C 소유권 분류가 그 교정이다. B(런타임 도구)와 C(upstream harness)를 옮기면 각각
`zsh/aliases/codex.zsh`의 런타임 호출과 upstream 동기화가 깨진다.

**P4. "손으로 짠 bash가 맞는 기반이다" — 검토된 적이 없다. 이게 가장 큰 미검증 전제다.**
0C-bis에서 다룬다.

**P5. "이 작업을 지금 하는 게 맞다" — 검증 필요.**
`docs/review-structural-2026-08-26.md`의 처리 순서 제안에서 이 리팩터는 10순위다.
1순위 S-01(HIGH: 공개 저장소에 사내 인프라 정보와 root 비밀번호 인증 절차)은 미처리로 보인다.
저장소가 여전히 public이면 순서가 뒤집혀 있다.

**아무것도 안 하면?** 새 기기 설치 때 Codex 설정이 통째로 누락되고, 그 사실을 알아채는 시점은
`codex` wrapper가 거부할 때다. 커밋 `aa4b8ff` 이후로는 tmux 완료 알림도 조용히 죽는다.
가설이 아니라 실측된 현재 동작이다.

## 0B. Existing Code Leverage

| 하위 문제 | 이미 있는 것 | 재사용 가능? |
|---|---|---|
| 멱등 링크 | `bootstrap.sh:128-140` `link_path` | 그대로. 재작성 금지 |
| 올바른 백업 경로 | `link-claude-home:63-74` `backup_path_for` | **이쪽을 `lib.sh`로 승격**. bootstrap.sh 버전이 버그 있는 쪽 |
| codex 링크 | `ai/.codex/init-home-codex` (32줄, 멱등, 백업 처리) | 호출만 하면 됨. 재구현 금지 |
| 상태 확인 | `--dry-run`이 이미 delta만 출력 | `--check`는 종료코드 + 비변경 보장만 추가하면 됨 |
| 격리 테스트 하네스 | `bootstrap-matrix-test.sh:8-15` HOME 격리 + git stub | 신규 테스트가 그대로 차용 |
| 테스트 러너 | `post-refactor-smoke-test.sh` | 한 줄 추가 |

**핵심:** `--check`는 신규 기능이 아니라 기존 `--dry-run`의 얇은 래퍼다. 플랜이 이걸
새 기능처럼 취급하면 필요 이상으로 크게 짓는다.

## 0C. Dream State

```
  CURRENT STATE                    THIS PLAN                    12-MONTH IDEAL
  ─────────────                    ─────────                    ──────────────
  2개 배타 모드                --->  단위 6개 + --all/--check --->  새 기기에서 한 줄로
  1회 실행 = 절반 반영              1회 실행 = 전체 반영              완전 재현, 상태는
  codex 누락                        codex 포함                      항상 조회 가능
  상태 조회 불가                     --check 로 조회                 drift 시 자동 알림
  실행경로 테스트 0                  단위별 계약 테스트                CI에서 매 push 검증
  백업 2곳 분산                      lib.sh 단일 구현                 백업 보존정책까지
```

## 0C-bis. Implementation Alternatives

```
APPROACH A: 단일 파일 유지 + 기능 추가 (minimal viable)
  Summary: bootstrap.sh 한 파일에 --all/--check/codex 단계를 추가하고
           G4/G5를 고친 뒤 멱등성 테스트를 붙인다. 파일 이동 없음.
  Effort:  S  (human ~4h / CC ~25min)
  Risk:    Low
  Pros:    - 실측으로 이미 멱등한 link_path를 건드리지 않는다
           - 변경 파일 3개(bootstrap.sh, 신규 테스트, 러너). 회귀 표면이 최소
           - G1·G2·G4·G5를 전부 닫는다. 즉 P1 교정 기준으로 실제 통증은 다 해결
  Cons:    - 파일이 300줄 근처로 커진다
           - 단위별 독립 실행은 이름 인자로만 되고 구조로 강제되지 않는다
           - 흩어진 헬퍼(link-claude-home, sync-secrets)는 그대로 남는다
  Reuses:  link_path, link-claude-home, init-home-codex, bootstrap-matrix 하네스

APPROACH B: 단위 분리 + lib.sh + scripts/ 통합 (플랜 원안, ideal architecture)
  Summary: bootstrap.d/ 아래 6단위 + lib.sh로 쪼개고 A그룹 헬퍼를 scripts/로 옮긴다.
  Effort:  M  (human ~2d / CC ~90min)
  Risk:    Med
  Pros:    - unit_check 계약이 --check와 단위별 테스트를 구조적으로 보장
           - backup_path_for 두 벌 분기(S-04)가 구조적으로 재발 불가
           - 단위 추가(예: 새 도구 설정)가 파일 하나 추가로 끝난다
  Cons:    - 사용자 1명, 기기 1~2대 기준으로 7파일 플러그인 구조는 과설계 위험
           - 변경 파일 ~17개. 회귀 표면이 A의 5배
           - A그룹 이동이 `~/.claude/scripts/`, `~/.hermes/scripts/` 배포 표면을 바꾼다
  Reuses:  동일 + post-refactor-smoke-test.sh

APPROACH C: 기성 도구 채택 (chezmoi / GNU stow)
  Summary: 손으로 짠 bash를 버리고 chezmoi 또는 stow로 이관한다.
  Effort:  L  (human ~1w / CC ~4h)
  Risk:    High
  Pros:    - 멱등성·백업·상태조회가 도구에 내장. 우리가 유지보수하지 않는다
           - chezmoi는 템플릿과 secret 통합(1Password, Bitwarden, keychain)을 제공
  Cons:    - **이 저장소의 핵심 설계와 호환되지 않는다.** `~/.claude`, `~/.codex`,
             `~/.hermes`는 저장소를 가리키는 심링크이고, 그래야 도구가 쓰는 런타임 상태가
             저장소 안에 떨어져 allowlist gitignore로 걸러진다. chezmoi는 source에서
             home으로 **복사**하므로 이 왕복이 끊긴다
           - stow는 심링크를 걸지만 파일 단위다. 런타임 상태가 섞인 디렉터리 통째 링크가 아니다
           - `ai/.codex`는 upstream harness를 vendor한 트리라 도구의 소유권 모델과 충돌
  Reuses:  없음. 사실상 재작성

RECOMMENDATION: **A를 먼저, B는 조건부.**
P1 교정에 따르면 실제 통증(G1·G2)은 A로 전부 해결되고, A는 "가장 작은 diff로 변경을 깔끔히
표현한다"는 선호에 맞는다. B의 고유 가치는 `unit_check` 계약 하나인데, 그건 A의 `--check`가
이미 90% 커버한다. 다만 B의 `lib.sh` 단일화는 S-04 재발을 구조적으로 막는 유일한 방법이라
가치가 있다. 아래 0D에서 B의 부분 채택을 cherry-pick으로 다룬다.
```

**[Layer 3 / Eureka]** 통념은 "손으로 짠 dotfiles bash를 버리고 chezmoi를 써라"다. 여기서는
틀리다. 이 저장소는 도구가 쓰는 런타임 상태를 저장소 안에 두고 allowlist gitignore로 거르는
설계이고, 그건 home→repo 심링크가 있어야 성립한다. chezmoi의 copy-apply 모델은 그 왕복을
끊는다. 검증 가능한 이유가 있는 반례다.

## 0D. Mode-Specific Analysis (SELECTIVE EXPANSION)

**Complexity check.** 원안 B는 신규 7 + 이동 4 + 문서 4 + 테스트 2 = 약 17파일. 8파일 기준을
넘으므로 smell로 처리하고 더 적은 부품으로 같은 목표에 도달하는지 물었다. 답은 A다.

**최소 변경 집합** (목표 1~5를 전부 달성하는):
1. `scripts/tests/bootstrap-idempotency-test.sh` 신설 + 러너 연결 → 목표 5, G3
2. `run_ai_stage`가 `init-home-codex` 호출 → 목표 1(부분), G2
3. `--all` 추가 → 목표 2, G1
4. `--check` 추가(`--dry-run` 위 얇은 래퍼 + 종료코드) → 목표 3
5. `backup_path_for`를 `link-claude-home` 구현으로 교체 → G4, S-04
6. `clone_if_missing`에 `rev-parse --verify HEAD` 추가 → G5

**Expansion 후보 (cherry-pick)**

| # | 후보 | 효과 | Effort |
|---|---|---|---|
| E1 | `lib.sh` 추출 — 공유 함수 한 벌 | S-04류 분기 재발을 구조적으로 차단 | S (human ~2h / CC ~15min) |
| E2 | `--list` + 단위 이름 인자 실행 | 단위별 독립 실행. 파일 분리 없이 함수 분리로 달성 가능 | S (human ~3h / CC ~20min) |
| E3 | 단위 의존 선언 + preflight 경고 | `--ai` 단독 실행 시 `~/.tmux` 없음을 경고. aa4b8ff 결합 해소 | S (human ~1h / CC ~10min) |
| E4 | A그룹 헬퍼를 `scripts/`로 이동 | 배포 표면 정리. 동작 변화 없음 | M (human ~4h / CC ~30min) |
| E5 | `--check`를 shell 시작 시 nag 또는 pre-push hook에 연결 | drift를 사람이 안 물어봐도 알게 됨 | S (human ~2h / CC ~15min) |
| E6 | 백업 보존 정책(prune) | 재실행마다 쌓이는 `.bak`을 정리 | S (human ~2h / CC ~15min) |

## 0E. Temporal Interrogation

```
  HOUR 1 (기반)      : 단위 계약의 종료코드 규약을 먼저 못박아야 한다.
                       check=1이 "미반영"인지 "오류"인지 섞이면 --check가 무의미해진다.
  HOUR 2-3 (핵심)    : --dry-run과 --check의 관계. 둘을 별개 코드경로로 만들면
                       즉시 갈라진다. check = dry-run + 종료코드로 정의해야 한다.
  HOUR 4-5 (통합)    : init-home-codex는 자기 위치를 링크 대상으로 삼는다.
                       bootstrap이 부를 때 DOTFILES_DIR와 어긋나면 엉뚱한 곳을 링크한다.
                       호출 전에 경로 일치를 검증해야 한다.
  HOUR 6+ (마감)     : 테스트가 실제 $HOME을 건드리지 않는다는 보장.
                       기존 테스트는 전부 --dry-run이라 이 위험이 없었다.
                       신규 테스트는 실제 mutation을 하므로 HOME 격리 실패 시
                       개발자 홈이 망가진다. 이게 이 작업 최대의 새 위험이다.
```

## 0F. Mode Selection

SELECTIVE EXPANSION 확정. 기준 접근은 A, E1~E6은 개별 판단 대상.

## Section 1: Architecture Review

**의존 그래프 (현재 → 제안 A)**

```
  현재                                        제안 A
  ────                                        ──────
  bootstrap.sh                                bootstrap.sh
   ├─ parse_args/validate/resolve_ts           ├─ parse_args (+ --all/--check/--list)
   ├─ preflight_shell ─┐                       ├─ preflight_* (동일)
   ├─ run_shell_stage ─┤ 배타                  ├─ stage_shell    ─┐
   │   ├─ clone_if_missing x5                  ├─ stage_terminal  │ --all 이 순차 호출
   │   └─ link_path x7                         ├─ stage_claude    │
   ├─ preflight_ai   ─┐                        ├─ stage_codex ★신규│
   └─ run_ai_stage   ─┘ 배타                   ├─ stage_hermes    │
       ├─ link-claude-home (외부)              └─ stage_secrets  ─┘
       ├─ link_path ~/.hermes                      │
       └─ printf 안내문 (codex 링크 안 함)         ├─ link-claude-home (외부, 유지)
                                                   ├─ init-home-codex (외부, 신규 호출)
                                                   └─ sync-secrets (외부, 유지)
```

**새로 생기는 결합.** `stage_codex`가 `stage_terminal`에 의존한다. 커밋 `aa4b8ff`가
Codex hook을 `$HOME/.tmux/scripts/ai-notify-hook.sh`로 옮겼고 `~/.tmux`는 terminal 단계가
링크하기 때문이다. 정당한 결합이 아니라 사고로 생긴 결합이다. `--all`이 순서를 보장하지만
`bootstrap codex` 단독 실행은 여전히 깨진다. E3(의존 선언 + preflight 경고)이 이 문제를 다룬다.

**단일 장애점.** `DOTFILES_DIR` 해석 한 곳이다. 기본값 `$HOME/dotfiles`가 실제 체크아웃과
다르면 모든 링크가 조용히 엉뚱한 곳을 가리킨다. `link_path`는 `readlink` 문자열 비교만 하므로
"틀린 경로를 정확히 가리키는" 상태를 정상으로 판정한다. `--check`가 대상 파일의 실재
여부까지 봐야 이걸 잡는다.

**10x 부하.** 해당 없음. 단위 6개, 링크 10개, clone 5개가 상한이고 사용자당 기기 1~2대다.
스케일 축은 존재하지 않으며, 이 사실 자체가 approach B의 과설계 위험 근거다.

**롤백 자세.** `git revert` 후 `bootstrap --all` 재실행. 링크는 멱등하므로 되돌림이 값싸다.
다만 이동한 A그룹 헬퍼(E4)는 revert 후 `~/.claude/scripts/`에서 사라진 상태가 남을 수 있어
revert 시 `--all` 재실행이 필수다. 이 절차가 문서에 없다.

**아름다움 관점.** 이 시스템의 좋은 형태는 "단위 6개 + 계약 3개"가 아니라
**"질문 하나에 답하는 CLI"** 다. `bootstrap --check`가 관리 대상 경로 전부와 각각의 상태를
한 화면에 보여주면, 나머지는 그 상태를 원하는 값으로 만드는 동작 하나로 충분하다.
단위 분리는 그 화면을 만들기 위한 수단일 때만 값을 한다.

**Findings:** 3건 (신규 결합 / DOTFILES_DIR SPOF / 롤백 절차 미문서화)

## Section 2: Error & Rescue Map

bash에는 예외 클래스가 없다. 대응물은 종료코드와 출력이다. 실측으로 매핑했다.

```
  CODEPATH                    | 무엇이 잘못될 수 있나          | 신호
  ----------------------------|--------------------------------|------------------
  backup_with_timestamp       | mv 실패(권한/디스크/교차장치)  | mv stderr
  link_path                   | ln 실패(대상 이미 존재)        | ln stderr + exit 20
  clone_if_missing            | git clone 실패(네트워크/인증)  | git stderr + exit 20
  clone_if_missing            | 중단된 clone(.git 만 존재)     | 없음 ← GAP
  run_command (dry-run)       | 항상 0 반환                    | 없음 ← 설계상 의도
  link-claude-home            | rsync 부재                     | die + exit 1
  run_ai_stage                | ~/.codex 미생성                | 없음 ← GAP
  init-home-codex (신규 호출) | DOTFILES_DIR 불일치            | 없음 ← GAP

  신호                        | 처리됨? | 처리 동작              | 사용자가 보는 것
  ----------------------------|---------|------------------------|------------------------
  mv 실패                     | N ← GAP | 없음. printf 가 마지막 | "backup: X -> Y" ← 거짓
  ln 실패                     | Y       | exit 20, 후속 중단     | ln stderr + exit 20
  git clone 실패              | Y       | exit 20                | error 라인 + exit 20
  중단된 clone                | N ← GAP | 없음                   | 아무것도 안 보임
  ~/.codex 미생성             | N ← GAP | 없음                   | 안내문(링크 얘기 없음)
```

**GAP-1 (CRITICAL). `backup_with_timestamp`가 실패한 백업에 성공 메시지를 출력한다.**
`bootstrap.sh:119-126`의 마지막 명령이 `printf`라 함수는 항상 0을 반환한다. 호출부가
`link_path ... || return 20` 안에 있어 `set -e`가 전체 서브트리에서 무력화되므로 `mv` 실패가
잡히지 않는다. 실측:

```
$ mv 를 실패하도록 스텁 → bootstrap.sh --shell-only
mv: simulated failure
backup: .zshrc -> .zshrc.bak.20260827-112149     ← 백업은 일어나지 않았다
ln: .../.zshrc: File exists
exit 20
$ ls ~/.zshrc.bak.*  → 없음.  ~/.zshrc → 원본 그대로
```

종료코드 20은 정확하고 후속 단계도 중단된다. 문제는 **출력이 거짓말을 한다**는 점이다.
사용자는 "backup:" 줄을 보고 원본이 안전하다고 믿는다. Prime Directive 1(무음 실패 금지)과
2(모든 에러에 이름을) 위반이다. 수정: `run_command mv ... || { error "backup failed: $target"; return 1; }`
로 바꾸고 `printf`를 성공 경로로 옮긴다.

**GAP-2. 중단된 clone.** `bootstrap.sh:147`이 `.git` 디렉터리 존재만 본다. 실측으로 재clone
0회, 깨진 상태 방치를 확인했다. 수정: `git -C "$target" rev-parse --verify HEAD`.

**GAP-3. `~/.codex` 미생성이 어떤 신호도 내지 않는다.** 안내문은 `local.config.toml` 얘기만
하고 링크 누락은 언급하지 않는다.

**GAP-4 (신규 위험). `init-home-codex`는 자기 위치를 링크 대상으로 삼는다**
(`init-home-codex:4` `HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`).
bootstrap이 `$DOTFILES_DIR/ai/.codex/init-home-codex`로 호출하는데 `DOTFILES_DIR`가 실제
체크아웃과 다르면 엉뚱한 트리를 `~/.codex`로 링크한다. 호출 전 경로 일치 검증이 필요하다.

**`--all` 도입이 만드는 새 질문.** 지금은 fail-fast가 옳다(단계가 하나뿐). `--all`에서는
단위 1 실패가 2~6을 통째로 막는다. 정책을 명시해야 한다. 권고: fail-fast 유지 + 종료 시
단위별 상태 요약 출력. 조용히 멈추는 것보다 "어디까지 됐는지"를 남기는 게 재실행 판단을 돕는다.

**Findings:** 4 GAP (1건 CRITICAL) + 정책 결정 1건

## Section 3: Security & Threat Model

| 위협 | 가능성 | 영향 | 완화됨? |
|---|---|---|---|
| 백업 실패를 성공으로 오인 → 사용자 설정 유실 | Med | High | **N** (GAP-1) |
| `DOTFILES_DIR` 오설정 → 임의 트리를 `~/.codex`로 링크 | Low | High | **N** (GAP-4) |
| 신규 테스트의 `HOME` 격리 실패 → 개발자 홈 파괴 | Low | Critical | **N** (신규) |
| `BACKUP_TIMESTAMP` 주입 | Low | Low | Y — `^[0-9]{8}-[0-9]{6}$` 정규식 검증 |
| secret 노출 | Low | High | Y — `sync-secrets:31` `umask 077`, 값은 iCloud 키 디렉터리에서만 읽음 |
| 공개 저장소 노출 (S-01) | — | High | **범위 밖.** 미처리로 보임 |

**입력 검증.** bootstrap의 외부 입력은 인자와 환경변수 4개(`DOTFILES_DIR`, `ZSH_CUSTOM_DIR`,
`BACKUP_ROOT`, `BACKUP_TIMESTAMP`)뿐이다. 타임스탬프만 검증되고 나머지 3개는 검증되지 않는다.
경로 3개는 사용자 자신이 주는 값이라 신뢰 경계 안이지만, `DOTFILES_DIR`은 오타 하나로
GAP-4를 발동시키므로 "디렉터리인가 + `zsh/`와 `ai/`를 포함하는가" 정도의 sanity check가 값싸다.

**가장 큰 신규 공격면은 테스트다.** 기존 테스트는 전부 `--dry-run`이라 파일시스템을 건드리지
않았다. 신규 멱등성 테스트는 실제 mutation을 한다. `HOME` 격리가 실패하면 개발자의 진짜 홈에
링크를 걸고 백업을 옮긴다. 방어: 테스트 시작 시 `[[ "$HOME" == "$TEST_ROOT"* ]]` assert를
넣고, 아니면 즉시 중단한다. 이건 선택이 아니라 필수다.

**Findings:** 3건 미완화 (1건은 신규 도입 위험) + 범위 밖 1건

## Section 4: Data Flow & Partial-State Edge Cases

UI가 없으므로 상호작용 대신 부분 상태를 추적한다.

```
  대상 경로 상태 ──▶ link_path 판정 ──▶ 동작 ──▶ 결과
       │                  │              │         │
       ▼                  ▼              ▼         ▼
  [없음]            링크 아님        ln -s      OK (실측)
  [올바른 심링크]    조기 return 0    없음       OK 멱등 (실측)
  [틀린 심링크]      -L 참            백업+링크  OK (실측)
  [깨진 심링크]      -L 참            백업+링크  OK (실측)
  [일반 파일]        -e 참            백업+링크  OK (실측)
  [일반 디렉터리]    -e 참            백업+링크  미검증 ← GAP
  [mv 실패]          -e 참            백업"성공" 거짓 보고 ← GAP-1 (실측)
```

`[일반 디렉터리]` 경로가 미검증이다. `~/.tmux`, `~/.claude`, `~/.codex`, `~/.hermes`는
디렉터리 링크이고, 실제 디렉터리가 자리에 있으면 `backup_with_timestamp`가 통째로 옮긴다.
`~/.claude`의 경우 `link-claude-home`이 rsync 병합을 먼저 하지만 `~/.tmux`는 그런 처리가
없다. TPM 플러그인이 `~/.local/share/tmux/plugins`에 있어 실제 손실은 작지만, 검증되지
않은 경로다. 신규 테스트가 커버해야 한다.

**Findings:** 1건 (디렉터리 백업 경로 미검증)

## Section 5: Code Quality Review

- **DRY 위반 (확인됨).** `backup_path_for`가 `bootstrap.sh:106-117`과
  `link-claude-home:63-74`에 두 벌 있고 이미 갈라졌다. 전자는 첫 후보를 `$HOME`에,
  후자는 `$BACKUP_ROOT`에 쓴다. 구조검토 S-04. E1(`lib.sh`)이 재발을 구조적으로 막는
  유일한 방법이다.
- **네이밍.** `run_shell_stage`가 shell과 terminal을 둘 다 한다. 이름이 내용을 속인다.
  단위 분리 시 자연히 해소된다.
- **과설계 점검.** approach B의 `unit_preflight`/`unit_check`/`unit_apply` 3함수 x 6단위 =
  18함수. 현재 총 로직이 231줄이다. 계약 자체는 값을 하지만 파일 6개로 나눌 필요는 없다.
  같은 파일 안 함수 명명 규약으로도 동일한 계약을 얻는다. **E1+E2가 B의 가치 대부분을
  B의 비용 없이 가져간다.**
- **저설계 점검.** GAP-1이 대표 사례다. 마지막 명령이 `printf`인 함수는 실패를 삼킨다.
  같은 패턴이 다른 곳에 있는지 확인 필요.
- **순환 복잡도.** 5분기 초과 함수 없음. `parse_args`가 5분기로 경계선이다.

**Findings:** 3건 (DRY / 네이밍 / B의 과설계 위험)

## Section 6: Test Review

```
  신규 코드경로
    - stage_codex (init-home-codex 호출 + 경로 검증)
    - --all 순차 실행
    - --check (비변경 + 종료코드)
    - --list
    - backup_path_for 교체본
    - clone_if_missing repo 유효성 검증
    - 단위 의존 preflight (E3 채택 시)

  신규 실패경로
    - backup mv 실패 (GAP-1 수정 후)
    - init-home-codex 경로 불일치 (GAP-4)
    - --all 중간 단위 실패
    - 중단된 clone 복구 (GAP-2)
```

| 항목 | 테스트 종류 | 존재? | happy | failure | edge |
|---|---|---|---|---|---|
| 2회 연속 실행 무변화 | 통합(격리 HOME) | N | 상태 해시 동일 | — | — |
| 링크 삭제 복구 | 통합 | N | 재링크됨 | — | — |
| 일반파일→링크 | 통합 | N | 백업+링크 | mv 실패 시 거짓보고 없음 | — |
| **디렉터리→링크** | 통합 | N | 백업+링크 | — | 내용 보존 |
| 깨진 심링크 복구 | 통합 | N | 재링크됨 | — | — |
| 중단된 clone 복구 | 통합 | N | 재clone | — | — |
| 백업 위치 단일성 | 통합 | N | 전부 BACKUP_ROOT | — | 같은 초 충돌 |
| `--check` 종료코드 | 통합 | N | 동기화 0 | drift 1 | 비변경 보장 |
| `--all` 전체 반영 | 통합 | N | 10경로 전부 링크 | 중간 실패 요약 | — |
| `--all` 후 `~/.codex` | 통합 | N | 링크됨 | — | — |
| **HOME 격리 assert** | 안전장치 | N | — | 격리 실패 시 즉시 중단 | — |

**2am 금요일 테스트:** 신규 기기에 `--all` 한 번 → 관리 대상 10경로 전부 링크 + `~/.codex`
포함 + `--check` 종료코드 0. 이게 통과하면 안심하고 잔다.

**적대적 QA 테스트:** `HOME`을 실제 홈으로 두고 테스트를 돌려본다. assert가 없으면 홈이 망가진다.

**카오스 테스트:** `--all` 도중 3번째 단위에서 `mv`를 실패시키고, 출력이 거짓 성공을 내지
않는지 + 어디까지 됐는지 요약이 남는지 확인.

**Flakiness 위험:** `BACKUP_TIMESTAMP`가 초 단위라 같은 초 재실행 시 충돌 경로를 탄다.
테스트는 `BACKUP_TIMESTAMP`를 고정 주입해 결정적으로 만든다(기존 테스트가 이미 하는 패턴).

**Findings:** 11개 항목 전부 미커버. 기존 테스트는 `--dry-run`만 봄.

## Section 7: Performance Review

관련 축이 사실상 없다. DB, 쿼리, 캐시, 커넥션 풀이 존재하지 않는다. 실행 시간을 지배하는 건
`clone_if_missing` 5회의 네트워크 왕복이고, 이미 존재하면 즉시 return 0이므로 재실행 비용은
거의 0이다. `--check`는 파일시스템 stat만 하므로 즉시 끝난다. 단위 분리로 인한 subshell
추가 비용은 측정 가능한 수준이 아니다. **No issues.**

## Section 8: Observability & Debuggability

- **로깅.** 유일한 신호가 stdout이고 구조화되어 있지 않다. 무엇이 바뀌었는지 사후 재구성이
  불가능하다. 재실행이 드문 도구라 파일 로그는 과하지만, `--all`이 생기면 **종료 시 단위별
  상태 요약**은 필요하다. Section 2의 정책 결정과 같은 항목이다.
- **상태 조회.** 지금은 없다. `--check`가 이걸 만든다. 이 리뷰에서 가장 큰 관측성 이득이다.
- **디버깅 가능성.** 3주 뒤 "왜 codex 설정이 없지?"를 물었을 때 지금은 답할 방법이 없다.
  `--check`가 관리 대상 전부와 상태를 나열하면 즉답이 된다.
- **운영 도구.** `--list`가 "이 저장소가 관리하는 것"의 목록을 코드에서 직접 뽑아준다.
  현재는 `README.md:84-86`과 `bootstrap.sh:186-192`가 각각 목록을 들고 있어 갈라질 수 있다.
  실제로 `~/.codex`는 README에 있지만 bootstrap에는 없다. **이미 갈라져 있다.**
- **runbook.** 각 GAP의 운영 대응이 문서에 없다.

**Findings:** 3건 (요약 출력 / 목록 이중화 이미 분기됨 / runbook 부재)

## Section 9: Deployment & Rollout

이 스크립트 자체가 배포 수단이다.

- **마이그레이션 안전성.** E4(A그룹 이동)가 유일한 파괴적 변경이다. `~/.claude/scripts/`와
  `~/.hermes/scripts/`에서 파일이 사라진다. 이 경로들을 직접 호출하는 곳은 문서뿐이지만
  (`docs/reference-bootstrap-cli.md`, `project-structure.md`) 사용자의 손 습관은 문서에 없다.
- **롤아웃 순서.** 테스트 → 기능 → 이동. 플랜의 1-2-3-4가 맞다.
- **롤백.** `git revert` + `bootstrap --all` 재실행. E4를 revert할 때 재실행이 필수라는 점이
  문서화되어야 한다.
- **부분 배포 위험.** 저장소를 pull했지만 `bootstrap`을 안 돌린 상태가 실재한다. 커밋
  `aa4b8ff`가 정확히 이 상태를 만들었다(tmux.conf는 심링크라 즉시 반영, hook은 반영). 다행히
  이번엔 전부 심링크라 자동 반영됐지만, `--all`이 필요한 변경이 들어오면 pull과 apply 사이
  간극이 생긴다. `--check`를 shell 시작에 물리는 E5가 이 간극을 좁힌다.
- **배포 후 검증.** `bootstrap --check` 종료코드 0 + `post-refactor-smoke-test.sh` 통과.

**Findings:** 2건 (E4 롤백 절차 / pull-apply 간극)

## Section 10: Long-Term Trajectory

- **기술 부채.** approach A는 부채를 줄인다(GAP 4건 해소, 테스트 신설). approach B는
  구조 부채를 줄이는 대신 파일 수 부채를 늘린다. 사용자 1명 기준 순효과가 불확실하다.
- **경로 의존성.** `unit_check` 계약을 정하면 이후 모든 단위가 그걸 따라야 한다. 계약을
  잘못 정의하면(특히 종료코드 규약) 되돌리기 비싸다. 0E HOUR 1이 이 지점이다.
- **지식 집중.** 사용자 1명 저장소라 "새 엔지니어" 축은 약하다. 다만 12개월 뒤 본인이
  읽었을 때 `--check` 종료코드 규약이 자명해야 한다.
- **되돌림 가능성: 4/5.** A는 5/5(단일 파일 수정). B의 E4 이동은 3/5(배포 표면 변경).
- **생태계 적합성.** 0C-bis의 eureka대로, 기성 도구로의 이관은 이 저장소의 심링크 설계와
  충돌한다. 손으로 짠 bash를 유지하는 선택은 정당하며, 그 이유가 문서에 기록되어야 한다.
  현재는 어디에도 없다.
- **1년 후 질문.** `--check`가 있으면 "지금 뭐가 반영돼 있나"에 즉답이 된다. 그게 이
  작업에서 12개월 뒤에도 남는 유일한 자산이다.
- **다음 단계.** E5(자동 drift 알림)가 자연스러운 Phase 2다. `--check`가 그 전제다.

**Findings:** 2건 (계약 정의 리스크 / bash 유지 근거 미문서화)

## Section 11: Design & UX Review

SKIPPED — UI 범위 없음. Phase 0 스캔에서 UI 용어 매치 0건.

## Step 0.5: Dual Voices

Codex: `[codex-unavailable: codex_reviews disabled by config]`. Claude subagent만 실행됨 → `[subagent-only]`.

### CLAUDE SUBAGENT (CEO — strategic independence)

평결: **지금 짓지 마라. 5%만 출하하고 나머지는 버려라.** 12건 지적(F-1~F-12).
핵심 논지는 이 플랜이 구조검토 10순위 작업이면서 1순위(S-01)를 명시적으로 비목표로 선언했고,
제안 단위 중 하나(`40-codex.sh`)가 오히려 그 1순위가 다루는 노출을 키운다는 것.

### 검증 결과 (subagent 주장을 액면으로 받지 않고 직접 확인)

| 주장 | 검증 | 판정 |
|---|---|---|
| 저장소가 PUBLIC | `gh repo view` → `"visibility":"PUBLIC"` | **사실** |
| `zsh/aliases/work.zsh`에 root 비밀번호가 하드코딩 | `sshpass -p` 리터럴 0건. 비밀번호는 환경변수 참조 | **과장** |
| 같은 파일에 사내 IP + 비밀번호 인증 절차 노출 | 추적 중. `root@<IP>` 3건, `PubkeyAuthentication=no` 3건 | **사실** (토폴로지·절차 노출) |
| `ai/`가 공개 저장소 작업트리에 GB급 런타임 상태 보유 | `.codex` 907M, `.claude` 107M, `.hermes` **3.4G** | **사실, 규모는 더 큼** |
| `auth.json`이 트리 안에 있음 | 존재하나 root `.gitignore`가 차단, **untracked** | **사실이나 위험은 낮음** |
| allowlist 봉쇄가 이미 깨져 유출 위험 | `ai/.codex/.gitignore`의 `*`는 신규 파일을 **무시**한다. 유출 방향으로는 fail-safe | **틀림** (반대 방향 문제) |
| 추적 중인 `.env`가 있음 | `ai/.hermes/.env` 추적됨. **키 14개 전부 값 없음 또는 `${}` 간접 참조**. 저장소 설계대로 | **문제 없음** |
| S-02(미커밋 agent 권한 확장)가 살아있음 | 작업트리에 미커밋으로 존재 | **사실, 아래 참조** |
| G2는 gap이 아니라 문서화된 결정 | `docs/reference-bootstrap-cli.md:133` "Codex는 의도적으로 자동 배포하지 않습니다" | **사실** |
| `link-claude-home:92` rsync가 최고 위험 경로인데 테스트 0 | `run rsync -a --ignore-existing "$path"/ "$SOURCE_DIR"/`, bootstrap이 `--yes` 전달 | **사실** |
| aa4b8ff cross-stage 의존 주장이 틀렸다 | `--ai`는 `~/.codex`를 안 만든다(실측). hook 자체가 등록되지 않음 | **사실. 내 주장이 틀렸다** |

**S-02 실물 (미커밋, Discord로 도달 가능한 agent의 command allowlist에 추가됨):**
```
+ recursive delete
+ execute_code
+ script execution via -e/-c flag
+ shell command via -c/-lc flag
+ pipe decoded content to shell (possible command obfuscation)
```

**내 Section 1 주장 정정.** "`--ai`만 돌린 기기에서 hook이 실패한다"는 틀렸다. `--ai`는
`~/.codex`를 만들지 않으므로 `hooks.json` 자체가 로드되지 않는다. 실제 결합 경로는
`init-home-codex`를 수동 실행했지만 shell 단계를 안 돌린 기기다. 영향도 낮다 —
Stop hook이 exit 127로 끝나고 로그 노이즈만 남는다. E3(의존 선언)의 유일한 근거가
이것이었으므로 **E3의 정당성이 사라졌다.**

### CEO DUAL VOICES — CONSENSUS TABLE

```
═══════════════════════════════════════════════════════════════
  Dimension                              Claude  Codex  Consensus
  ──────────────────────────────────────  ──────  ─────  ─────────
  1. Premises valid?                      NO      N/A    NO (단독)
  2. Right problem to solve?              NO      N/A    NO (단독)
  3. Scope calibration correct?           NO      N/A    NO (단독)
  4. Alternatives sufficiently explored?  NO      N/A    NO (단독)
  5. Competitive/market risks covered?    N/A     N/A    N/A
  6. 6-month trajectory sound?            NO      N/A    NO (단독)
═══════════════════════════════════════════════════════════════
Codex 부재로 CONFIRMED 0. 단, 두 축(내 0A 전제검증, subagent)이
독립적으로 같은 결론에 도달: 순서가 뒤집혔고 범위가 과하다.
```

### 두 축이 독립적으로 일치한 지점

- **P1/F-5**: 실제 통증은 멱등성이 아니라 1회 실행 완결성. 값어치 있는 부분은 4~60줄.
- **P5/F-1**: 구조검토 순서상 이 작업은 10순위, S-01은 1순위이며 미처리.
- **B 과설계/F-6**: 사용자 1명·기기 1~2대에 7파일 플러그인 구조는 과하다.
- **E1/F-7(a)**: `backup_path_for` 중복은 `lib.sh`가 아니라 한 벌 삭제로 해결된다.
- **E3/F-8**: cross-stage 의존 근거가 사실이 아니므로 E3는 폐기.

### 두 축이 갈린 지점

- **`--check` 가치.** 내 Section 8은 이 리뷰 최대의 관측성 이득으로 봤다. subagent(F-11)는
  소비자가 없다고 본다(CI 없음, `ls -ld` 4개로 같은 답). **양쪽 다 맞다.** `--check`는 값을
  하되 18함수 계약 없이 25줄 평면 구현으로 충분하다는 게 합의점이다.
- **`40-codex.sh`.** 내 G2는 이걸 구멍으로 봤다. subagent(F-2, F-3)는 문서화된 안전 결정을
  뒤집는 것이며 공개 저장소를 홈 디렉터리에 링크하는 걸 `--all`의 부작용으로 만든다고 본다.
  검증 결과 F-3이 맞다. **G2는 gap이 아니라 결정 재검토 항목이다.**

## Premise Gate — 사용자 결정

**결정: approach B 원안 진행.** 단위 분리 + `lib.sh` + `scripts/` 통합 + `--all`/`--check` 전부.
보안 항목(S-01, S-02)은 이 작업 후 별도 처리.

두 축이 순서 재배치를 권고했고 사용자가 원안을 재확인했다. 원안이 결정이다.
아래는 그 결정을 뒤집지 않으면서 B에 그대로 적용되는 CEO findings다.

### B에 반드시 반영해야 하는 CEO findings

| # | 출처 | 내용 | 반영 위치 |
|---|---|---|---|
| C1 | Section 2 GAP-1 **CRITICAL** | `backup_with_timestamp`가 실패한 백업에 성공 메시지 출력. 마지막 명령이 `printf`라 항상 0 반환 | `lib.sh` 이관 시 수정 |
| C2 | Section 2 GAP-4 | `init-home-codex`가 자기 위치를 링크 대상으로 삼음. `DOTFILES_DIR` 불일치 시 엉뚱한 트리 링크 | `40-codex.sh` 호출 전 경로 일치 검증 |
| C3 | Section 3 **신규 위험** | 신규 테스트가 실제 mutation을 함. `HOME` 격리 실패 시 개발자 홈 파괴 | 테스트 시작에 `[[ "$HOME" == "$TEST_ROOT"* ]]` assert 필수 |
| C4 | subagent F-9 | `link-claude-home:92` rsync가 `--yes`로 실제 `~/.claude` 내용을 공개 저장소 트리에 복사. 테스트 0건 | step 1 테스트의 **첫 항목**으로 |
| C5 | subagent F-3 | G2는 gap이 아니라 문서화된 결정의 반전 (`reference-bootstrap-cli.md:133`) | `docs/decisions.md`에 반전 근거 기록 |
| C6 | subagent F-2 | `--all`에 codex를 넣으면 공개 저장소 트리를 홈에 링크하는 게 기본 동작이 됨 | `--all`의 codex 포함 여부를 명시적으로 결정·기록 |
| C7 | subagent F-4 | `--all`이 secrets 단위를 포함하는지 미명시. 포함 시 무동의로 iCloud 키를 읽음 | **secrets는 `--all`에서 제외** 명시 |
| C8 | Section 2 정책 | `--all`에서 단위 1 실패가 2~6을 막음 | fail-fast 유지 + 종료 시 단위별 상태 요약 출력 |
| C9 | Section 1 | `DOTFILES_DIR` SPOF. `link_path`는 문자열 비교만 해 "틀린 경로를 정확히 가리키는" 상태를 정상 판정 | `--check`가 대상 파일 실재 여부까지 확인 |
| C10 | Section 8 | 관리 대상 목록이 `README.md:84-86`과 `bootstrap.sh:186-192`에 이중화, 이미 분기됨(`~/.codex`) | `--list`가 코드에서 단일 출처로 생성 |
| C11 | Section 9 | E4 revert 시 `--all` 재실행이 필수인데 문서에 없음 | 롤백 절차 문서화 |
| C12 | Section 10 | bash 유지 근거(chezmoi 심링크 비호환)가 어디에도 없음 | `docs/decisions.md`에 기록 |

### 폐기된 항목

- **E3 (단위 의존 선언).** 유일한 근거였던 aa4b8ff cross-stage 의존 주장이 사실이 아님이
  실측으로 확인됨(`--ai`는 `~/.codex`를 만들지 않으므로 hook이 등록조차 되지 않는다).
  n=6 단위에서는 오케스트레이터의 고정 실행 순서가 필요한 순서 보장의 전부다.
- **`bootstrap.sh` → `bootstrap` 개명 (F-12).** 테스트 4곳 + 문서 4곳을 고쳐야 하고,
  얻는 건 우리 소유가 아닌 upstream harness와의 표기 일치뿐이다.

### Decision Audit Trail

| # | Phase | Decision | Class | Principle | Rationale |
|---|-------|----------|-------|-----------|-----------|
| 1 | CEO | Mode = SELECTIVE EXPANSION | Mechanical | P6 | autoplan 기본값 |
| 2 | CEO | approach B 채택 | **User Challenge → 사용자 결정** | — | 두 축이 A 권고, 사용자가 B 재확인. 원안이 결정 |
| 3 | CEO | C1 GAP-1 수정을 B 범위에 포함 | Mechanical | P1 | CRITICAL 무음 실패. blast radius 안 |
| 4 | CEO | C3 HOME 격리 assert 필수화 | Mechanical | P1 | 신규 테스트가 만드는 최대 위험 |
| 5 | CEO | C4 rsync 마이그레이션 테스트를 최우선 | Taste | P1 | 최고 위험 경로인데 원안 테스트 6개가 모두 비껴감 |
| 6 | CEO | C7 secrets를 `--all`에서 제외 | Mechanical | P5 | 무동의 키 접근 방지. 명시가 암묵보다 낫다 |
| 7 | CEO | C8 fail-fast 유지 + 상태 요약 | Taste | P3 | 조용히 멈추는 것보다 어디까지 됐는지가 재실행 판단을 돕는다 |
| 8 | CEO | E3 폐기 | Mechanical | P4 | 근거가 사실이 아님. 중복 기제 |
| 9 | CEO | 개명 폐기 (F-12) | Mechanical | P3 | 비용만 있고 이득 없음 |
| 10 | CEO | E1/E2/E4/E5/E6은 B에 포함 | Mechanical | P1 | B 원안이 이미 포함. 사용자 결정 존중 |
