unalias godcprd godcstg godcdev 2>/dev/null

godcprd() {
  load_oke_vars || return $?
  sshpass -p "$DC_TRB_PRD" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@10.255.37.211
}

godcstg() {
  load_oke_vars || return $?
  sshpass -p "$DC_TRB_STG" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@10.255.12.119
}

godcdev() {
  load_oke_vars || return $?
  sshpass -p "$DC_TRB_DEV" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@10.255.17.235
}
