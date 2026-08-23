#!/usr/bin/env zsh

if (( $+commands[rbenv] )); then
  typeset -g RUBY_SHIMS_DIR="$(rbenv root 2>/dev/null)/shims"
fi
