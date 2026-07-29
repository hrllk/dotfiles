# Dotfiles documentation

이 저장소는 macOS 개발환경의 셸, 터미널, tmux, 에디터, Codex 설정을 관리합니다. 설정은 홈 디렉터리에 직접 복사하지 않고 저장소의 파일을 symlink로 연결하는 방식으로 배포합니다.

## 문서 안내

처음 설치한다면 다음 순서로 읽습니다.

1. [첫 설치 Tutorial](tutorial-first-setup.md)
2. [Bootstrap How-to](howto-bootstrap.md)
3. [프로젝트 구조 Reference](project-structure.md)
4. [아키텍처 Explanation](explanation-architecture.md)

이미 설치한 환경을 수정하려면 [Bootstrap How-to](howto-bootstrap.md)의 재실행, 검증, 문제 해결 절차를 사용합니다.

## 기능별 문서

- [Codex tmux unread 설계](design-codex-tmux-unread.md): Codex 완료 상태를 tmux window에 표시하는 설계
- [Codex tmux unread 테스트 계획](eng-review-test-plan-codex-tmux-unread.md): 격리된 tmux 서버에서 검증하는 시나리오
- [결정 기록](decisions.md): 저장소의 장기적인 설정 결정

## 문서 범위

이 저장소는 실행 애플리케이션이 아니므로 API 문서 대신 다음을 문서화합니다.

- bootstrap이 설치하고 연결하는 파일과 외부 의존성
- zsh 초기화 순서와 모듈별 책임
- 터미널·tmux·Codex 설정의 배포 경로
- 사용자가 직접 실행하는 alias, 함수, 검증 명령

