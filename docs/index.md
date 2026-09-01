# Dotfiles documentation

이 저장소는 macOS 개발환경의 셸, 터미널, tmux, 에디터, AI 도구 설정을 관리합니다. 설정은 홈 디렉터리에 복사하지 않고 저장소의 파일을 symlink로 연결하는 방식으로 배포합니다.

## 문서 안내

처음 설치한다면 다음 순서로 읽습니다.

1. [첫 설치 Tutorial](tutorial-first-setup.md) — 새 Mac에서 동작하는 환경까지
2. [Bootstrap How-to](howto-bootstrap.md) — 재실행, 검증, 문제 해결
3. [Shell command reference](reference-shell-commands.md) — 설치 후 쓸 수 있는 명령 전체
4. [아키텍처 Explanation](explanation-architecture.md) — startup 순서와 책임 경계

이미 설치한 환경에 설정을 추가하려면 [How to add configuration](howto-add-configuration.md)을 사용합니다.

## Diataxis 분류

### Tutorial — 배우기 위해

| 문서 | 내용 |
|---|---|
| [첫 설치](tutorial-first-setup.md) | 새 Mac에서 셸, completion, tmux, Codex가 동작하는 상태까지 |

### How-to — 특정 작업을 위해

| 문서 | 내용 |
|---|---|
| [Bootstrap](howto-bootstrap.md) | 설치, 재실행, 검증, 문제 해결 |
| [설정 추가](howto-add-configuration.md) | alias, 모듈, secret 도메인, Hermes profile 추가. gitignore allowlist 우회 절차 |

### Reference — 정확한 사실을 찾기 위해

| 문서 | 내용 |
|---|---|
| [프로젝트 구조](project-structure.md) | 디렉터리 소유 경계와 배포 경로 |
| [Shell command](reference-shell-commands.md) | alias, 함수, lazy wrapper, secret loader, 키 바인딩 전체 |
| [Bootstrap CLI](reference-bootstrap-cli.md) | flag, 환경변수, 종료 코드, 링크 대상 |
| [Hermes gateway](reference-hermes-gateways.md) | profile, wrapper, launchd 연동, 관리 스크립트 |

### Explanation — 왜 그런지 이해하기 위해

| 문서 | 내용 |
|---|---|
| [설정 아키텍처](explanation-architecture.md) | startup 순서, 모듈 책임, optional dependency 처리 |
| [Secret handling](explanation-secret-handling.md) | key 파일과 환경변수 사이의 간접 계층, allowlist gitignore를 쓰는 이유 |

## 기능별 문서

- [AI agent tmux unread 설계](design-codex-tmux-unread.md): Codex와 Claude Code의 완료 상태와 답변 대기 상태를 tmux window에 표시하는 공용 설계
- [AI agent tmux unread 테스트 계획](eng-review-test-plan-codex-tmux-unread.md): 격리된 tmux 서버에서 검증하는 시나리오

## 검토와 결정 기록

- [구조 검토 (2026-08-26)](review-structural-2026-08-26.md): 구조적 문제와 변경 후보 목록
- [결정 기록](decisions.md): 저장소의 장기적인 설정 결정

## 문서 범위

이 저장소는 실행 애플리케이션이 아니므로 API 문서 대신 다음을 문서화합니다.

- bootstrap이 설치하고 연결하는 파일과 외부 의존성
- zsh 초기화 순서와 모듈별 책임
- 터미널·tmux·AI 도구 설정의 배포 경로
- 사용자가 직접 실행하는 alias, 함수, 검증 명령

runtime state(로그, cache, database, session, heartbeat)와 secret 값은 문서화 대상이 아닙니다.
