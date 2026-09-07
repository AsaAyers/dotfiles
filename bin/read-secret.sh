#!/bin/bash

_SECRET_KEYS=""
_SECRET_KEYS_STALE=1

_secret_cache_keys() {
  if [ "$_SECRET_KEYS_STALE" -eq 1 ]; then
    _SECRET_KEYS="$(sops decrypt ~/.bashrc.json 2>/dev/null | jq -r 'keys[]')"
    _SECRET_KEYS_STALE=0
  fi
  echo "$_SECRET_KEYS"
}

secret() {
  local cmd="${1:-help}"
  shift 2>/dev/null

  case "$cmd" in
    list)
      _secret_cache_keys
      ;;
    read)
      if [ -z "$1" ]; then
        echo "Usage: secret read <KEY>"
        return 1
      fi
      sops decrypt --extract "['$1']" ~/.bashrc.json
      echo ""
      ;;
    load)
      if [ -z "$1" ]; then
        echo "Usage: secret load <KEY>"
        return 1
      fi
      export "$1=$(secret read "$1")"
      ;;
    drop)
      if [ -z "$1" ]; then
        echo "Usage: secret drop <KEY>"
        return 1
      fi
      unset "$1"
      ;;
    edit)
      sops edit ~/.bashrc.json
      _SECRET_KEYS_STALE=1
      ;;
    help|*)
      echo "Usage: secret <command> [key]"
      echo ""
      echo "Commands:"
      echo "  list        List all secret keys"
      echo "  read <KEY>  Print a secret value"
      echo "  load <KEY>  Export a secret into the current shell"
      echo "  drop <KEY>  Unset an exported secret"
      echo "  edit        Open the secrets file for editing"
      ;;
  esac
}

_secret_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local cmds="list read load drop edit help"

  if [ "$COMP_CWORD" -eq 1 ]; then
    mapfile -t COMPREPLY < <(compgen -W "$cmds" -- "$cur")
  elif [ "$prev" = "read" ] || [ "$prev" = "load" ] || [ "$prev" = "drop" ]; then
    local keys
    keys="$(_secret_cache_keys)"
    mapfile -t COMPREPLY < <(compgen -W "$keys" -- "$cur")
  fi
}

complete -F _secret_complete secret
