autoload -Uz is-at-least

if ! is-at-least 5.1; then
  return 0
fi

set zle_bracketed_paste

bindkey -N bracketed-paste
bindkey -RM bracketed-paste '\x00-\xFF' bracketed-paste-enqueue
bindkey -M main '^[[200~' _bracketed_paste_begin
bindkey -M bracketed-paste '^[[201~' _bracketed_paste_end
bindkey -M bracketed-paste -s '^M' '^J'

zle -N _bracketed_paste_begin
zle -N _bracketed_paste_end
zle -N bracketed-paste-enqueue _bracketed_paste_enqueue

if typeset -f hooks-add-hook >/dev/null 2>&1; then
  hooks-add-hook zle_line_init_hook _bracketed_paste_zle_init
  hooks-add-hook zle_line_finish_hook _bracketed_paste_zle_finish
else
  zle -N zle-line-init _bracketed_paste_zle_init
  zle -N zle-line-finish _bracketed_paste_zle_finish
fi

_bracketed_paste_begin() {
  _bracketed_paste_restore_keymap=( ${(z)"$(bindkey -lL main)"} )
  bindkey -A bracketed-paste main
}

_bracketed_paste_end() {
  local content="${_bracketed_paste_content//$'\r\n'/$'\n'}"
  content="${content//$'\r'/$'\n'}"

  if [ ${_bracketed_paste_restore_keymap[@]:0:1} = 'bindkey' ]; then
    $_bracketed_paste_restore_keymap
  fi
  LBUFFER+="$content"
  unset _bracketed_paste_content _bracketed_paste_restore_keymap
}

_bracketed_paste_enqueue() {
  _bracketed_paste_content+=$KEYS
}

_bracketed_paste_zle_init() {
  _bracketed_paste_content=''
  if [[ $TERM =~ '^(rxvt-unicode|xterm(-256color)?|screen(-256color)?)$' ]]; then
    printf '\e[?2004h'
  fi
}

_bracketed_paste_zle_finish() {
  if [[ $TERM =~ '^(rxvt-unicode|xterm(-256color)?|screen(-256color)?)$' ]]; then
    printf '\e[?2004l'
  fi
}
