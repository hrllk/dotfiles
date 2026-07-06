unalias godcprd godcstg godcdev 2>/dev/null

__sshpass_cmd() {
  local sshpass_bin

  sshpass_bin="$(command -v sshpass 2>/dev/null)" || true
  if [[ -n "$sshpass_bin" && -x "$sshpass_bin" ]]; then
    print -r -- "$sshpass_bin"
    return 0
  fi

  sshpass_bin="$(brew --prefix sshpass 2>/dev/null)/bin/sshpass"
  if [[ -x "$sshpass_bin" ]]; then
    print -r -- "$sshpass_bin"
    return 0
  fi

  echo "sshpass not found; run: brew install sshpass" >&2
  return 127
}

__godc_require_known_host() {
  local host="$1"

  if ssh-keygen -F "$host" >/dev/null 2>&1; then
    return 0
  fi

  print -u2 "godc: host key for $host is not in known_hosts"
  print -u2 "godc: run 'ssh root@$host' once to verify the fingerprint, then retry"
  return 6
}

godcprd() {
  load_oke_vars || return $?
  local sshpass_bin
  __godc_require_known_host 10.255.37.211 || return $?
  sshpass_bin="$(__sshpass_cmd)" || return $?
  "$sshpass_bin" -p "$DC_TRB_PRD" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@10.255.37.211
}

godcstg() {
  load_oke_vars || return $?
  local sshpass_bin
  __godc_require_known_host 10.255.12.119 || return $?
  sshpass_bin="$(__sshpass_cmd)" || return $?
  "$sshpass_bin" -p "$DC_TRB_STG" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@10.255.12.119
}

godcdev() {
  load_oke_vars || return $?
  local sshpass_bin
  __godc_require_known_host 10.255.17.235 || return $?
  sshpass_bin="$(__sshpass_cmd)" || return $?
  "$sshpass_bin" -p "$DC_TRB_DEV" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@10.255.17.235
}
