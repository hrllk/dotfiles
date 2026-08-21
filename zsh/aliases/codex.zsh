# Codex profile wrapper

_codex_local_profile_path() {
  print -r -- "${CODEX_HOME:-$HOME/.codex}/local.config.toml"
}

_codex_require_local_profile() {
  local profile_path owner mode
  profile_path="$(_codex_local_profile_path)"

  if [[ ! -f "$profile_path" ]]; then
    print -u2 "Codex local profile is missing: local.config.toml"
    print -u2 "Create it from: ${CODEX_HOME:-$HOME/.codex}/local.config.toml.example"
    return 1
  fi

  owner="$(stat -f %Su -- "$profile_path" 2>/dev/null)" || {
    print -u2 "Unable to inspect Codex local profile permissions"
    return 1
  }
  if [[ "$owner" != "$(id -un)" ]]; then
    print -u2 "Codex local profile must be owned by the current user"
    return 1
  fi

  mode="$(stat -f %Lp -- "$profile_path" 2>/dev/null)" || {
    print -u2 "Unable to inspect Codex local profile permissions"
    return 1
  }
  if (( 8#$mode & 18 )); then
    print -u2 "Codex local profile must not be group/world-writable"
    print -u2 "Fix with: chmod 600 $profile_path"
    return 1
  fi
}

_codex_has_explicit_profile() {
  local arg
  local expect_value=0
  local explicit=0
  for arg in "$@"; do
    if (( expect_value )); then
      [[ -n "$arg" ]] || return 2
      expect_value=0
      continue
    fi
    [[ "$arg" == "--" ]] && { (( explicit )) && return 0; return 1; }
    case "$arg" in
      -p|--profile)
        expect_value=1
        explicit=1
        ;;
      --profile=*)
        [[ -n "${arg#--profile=}" ]] || return 2
        return 0
        ;;
      -p?*)
        return 0
        ;;
    esac
  done
  (( expect_value )) && return 2
  (( explicit )) && return 0
  return 1
}

codex() {
  local profile_result
  if _codex_has_explicit_profile "$@"; then
    profile_result=0
  else
    profile_result=$?
  fi
  case "$profile_result" in
    0)
      command codex "$@"
      return $?
      ;;
    2)
      print -u2 "Codex profile option requires a non-empty profile name"
      return 2
      ;;
  esac

  _codex_require_local_profile || return $?
  command codex -p local "$@"
}
