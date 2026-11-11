# Terminal theme

wezterm, tmux, k9s, nvim이 한 팔레트를 공유합니다. 목표는 화면에서 색이 있는 것이 코드뿐이고, 크롬(테두리·상태바)은 한 가지 뜻만 갖게 하는 것입니다.

## 팔레트

nvim이 쓰는 sonokai "andromeda"를 그대로 가져옵니다. 출처는 `sonokai/autoload/sonokai.vim`.

| 역할 | 값 | 쓰이는 곳 |
|---|---|---|
| orange | `#F89860` | wezterm 창 테두리, tmux pane border, AI 알림 |
| dim orange | `#6B4226` | 비활성 pane border, copy-mode 선택 |
| fg | `#E1E3E4` | 기본 전경 |
| grey | `#7E8294` | 비활성 window 이름 |
| grey_dim | `#5A5E7A` | 포커스 없는 터미널의 상태바 |

정의 위치는 `util/wezterm/wezterm.lua`의 `sonokai` 테이블과 `util/tmux/.tmux.conf` 상단입니다. 두 곳의 리터럴은 같아야 합니다.

## 규칙 하나: 상태바의 오렌지는 "이 window가 너를 원한다"

tmux 상태바에서 오렌지는 이 뜻 하나만 갖습니다.

| 상태 | 색 |
|---|---|
| idle | `#7E8294` |
| 현재 window | `#E1E3E4` (무채색) |
| `@ai_unread` — 턴이 끝났고 아직 안 봄 | `#F89860` |
| `@ai_waiting` — 답을 기다림 | `#F89860` + bold |

현재 window가 무채색인 건 의도입니다. 어느 window에 있는지는 화면이 이미 말해주므로, 크롬의 유일한 유채색을 거기 쓸 이유가 없습니다. bold는 "답해줘"에만 남겨서 굵기가 "여기 봐"로 희석되지 않게 합니다.

tmux 자체 알림(`window-status-bell-style`, `window-status-activity-style`)도 같은 오렌지입니다. 기본값이 `reverse`인데, 그러면 전경이 배경으로 뒤집혀 블록이 됩니다. 벨과 `@ai_unread`는 뜻도("이 window가 너를 원한다") 해제 조건도(방문하면 사라짐) 같으므로 생김새도 같아야 합니다.

## 포커스 표시가 tmux에 있는 이유

터미널 창이 여럿일 때 어느 창이 포커스를 가졌는지는 **tmux 상태바 밝기**로 표시합니다(`client-focus-in` / `client-focus-out` 훅, slot 97). wezterm 창 테두리는 오렌지 고정입니다.

wezterm에는 창 테두리를 바꾸는 API가 `set_config_overrides`밖에 없고, 이건 설정 전체를 재평가하고 창을 GUI 스레드에서 재구성합니다. 창 전환마다 두 창이 이 비용을 내면 전환 직후 입력이 한 박자 멈춥니다. 상태바를 다시 그리는 건 그에 비하면 공짜입니다.

훅이 `set-option`을 `-g` 없이 쓰므로 세션 옵션에 기록됩니다. **터미널 창 하나당 tmux 세션 하나**를 전제하며, 두 창이 한 세션을 보면 서로 덮어씁니다.

AI 오렌지는 이 어두워짐에서 제외됩니다. `window-status-format`이 직접 칠하기 때문이고, 안 보고 있는 터미널이야말로 그 신호가 필요한 곳입니다.

## k9s는 팔레트 값을 그대로 못 쓴다

`util/k9s/skins/sonokai-orange.yaml`은 위 리터럴이 아니라 **그 값이 양자화되어 도달하는 xterm-256 항목**을 적습니다.

k9s는 tcell로 렌더하는데, tcell은 truecolor 여부를 `COLORTERM`이 아니라 terminfo에서 판단합니다. `TERM=tmux-256color`에서는 256색으로 떨어지고, **팔레트 항목 사이에 있는 색은 엉뚱하게 변환됩니다**. 실측(k9s 0.51.0):

```
#F89860 → #8787FF (보라)    #6DCAE8 → #87AFAF (탁한 청록)
#6B4226 → #8787AF           #7E8294 → #87AFFF
```

항목 위에 정확히 올라앉은 색은 그대로 통과합니다. 그래서 `#F89860` 대신 `#FF875F`(209), `#6B4226` 대신 `#875F00`(94)을 씁니다.

**이 파일의 색을 고치면 눈으로 확인하지 말고 측정하십시오.** `body.logoColor` 하나만 설정하고 ASCII 로고가 칠해지는 SGR을 읽으면 됩니다.

## 트레이드오프

- wezterm 창 테두리가 포커스를 표시하지 않습니다. 전환 지연과 맞바꿨습니다.
- k9s 오렌지는 `#FF875F`로, tmux의 `#F89860`과 미세하게 다릅니다. k9s가 어차피 256색으로 떨어뜨리므로 실제 렌더 결과는 같습니다.
- 팔레트 리터럴이 wezterm·tmux·k9s 세 곳에 중복됩니다. 형식이 달라 공유가 안 되므로, 하나를 바꾸면 나머지도 확인해야 합니다.
