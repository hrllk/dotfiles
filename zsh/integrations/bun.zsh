#!/usr/bin/env zsh

if [[ -n "${BUN_INSTALL:-}" ]]; then
  typeset -g BUN_BIN_DIR="$BUN_INSTALL/bin"
fi
