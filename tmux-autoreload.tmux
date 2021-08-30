#!/usr/bin/env bash

# Watches your tmux configuration file and automatically reloads it on change.
#
# Copyright 2021 Maddison Hellstrom <github.com/b0o>, MIT License.

set -Eeuo pipefail
if [[ ${BASH_VERSINFO[0]} -ge 5 || (${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -ge 4) ]]; then
  shopt -s inherit_errexit
fi

function years_from() {
  local from="$1" to
  to="${2:-$(date +%Y)}"
  if [[ "$from" == "$to" ]]; then
    echo "$from"
  else
    echo "$from-$to"
  fi
}

declare -g self prog name
self="$(realpath -e "${BASH_SOURCE[0]}")"
prog="$(basename "$self")"
name="${prog%.tmux}"

declare -gr version="0.0.1"
declare -gr authors=("$(years_from 2021) Maddison Hellstrom <github.com/b0o>")
declare -gr repo_short="b0o/$name"
declare -gr repository="https://github.com/$repo_short"
declare -gr issues="https://github.com/$repo_short/issues"
declare -gr license="MIT"
declare -gr license_url="https://mit-license.org"

declare -gi tmux_autoreload_pid=-1

function usage() {
  cat << EOF
Usage: $prog [-f] [OPT...]

Watches your tmux configuration file and automatically reloads it on change.

Options
  -h      Display usage information.
  -v      Display $name version and copyright information.
  -f      Run in foreground (do not fork).
  -k      Kill the running instance of $name.
  -s      Show status of $name.
  -m MSG  Display MSG on all clients.
  -M MSG  Display MSG on all clients (wait for keypress).

To enable $name, install TPM (https://github.com/tmux-plugins/tpm) and add the
following line to the end of your tmux configuration file:

    set-option -g @plugin '$repo_short'

If you do not use a plugin manager, you can run $name directly:

    run-shell "$self"

EOF
}

function usage_version() {
  cat << EOF
$name v$version

Repository: $repository
Issues:     $issues
License:    $license ($license_url)
Copyright:  ${authors[0]}
EOF
  if [[ ${#authors[@]} -gt 1 ]]; then
    printf '              %s\n' "${authors[@]:1}"
  fi
}

function display_message() {
  # `tmux display-message -c` is broken in v3.2a
  # https://github.com/tmux/tmux/issues/2737#issuecomment-898861216
  if [[ "$(tmux display-message -p "#{version}")" == "3.2a" ]]; then
    tmux display-message "$@"
  else
    while read -r client; do
      tmux display-message -c "$client" "$@"
    done < <(tmux list-clients -F '#{client_name}')
  fi
}

function get_instance() {
  tmux_autoreload_pid="$(tmux show-options -gv @tmux-autoreload-pid)"
  if [[ "$tmux_autoreload_pid" -gt 0 ]] && ps "$tmux_autoreload_pid" &> /dev/null; then
    return 0
  fi
  return 1
}

function main() {
  if ! [[ "${1:-}" =~ ^-[hvfks]$ ]]; then
    "$self" -f "$@" &> /dev/null &
    disown
    exit $?
  fi

  local opt OPTARG
  local -i OPTIND
  while getopts "hvfksm:M:" opt "$@"; do
    case "$opt" in
    h)
      usage
      return 0
      ;;
    v)
      usage_version
      return 0
      ;;
    f) ;;
    k)
      if get_instance; then
        kill "$tmux_autoreload_pid"
        return $?
      fi
      echo "$name -k: kill failed: no instance found" >&2
      return 1
      ;;
    s)
      if get_instance; then
        echo "running: $tmux_autoreload_pid"
        return 0
      fi
      echo "not running"
      return 1
      ;;
    m)
      display_message "$OPTARG"
      return $?
      ;;
    M)
      display_message -d 0 "$OPTARG"
      return $?
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  command -v entr &> /dev/null || {
    echo "command not found: entr" >&2
    "$self" -M "failed to start tmux-autoreload: command not found: entr"
    return 1
  }

  local -i entr_pid

  if get_instance; then
    return 0
  fi

  local -a config_files
  readarray -t config_files < <(tmux display-message -p "#{config_files}")

  function onexit() {
    local -i code=$?
    {
      "$self" -m "tmux-autoreload exited with code $code"
      if [[ -v entr_pid && $entr_pid -gt 1 ]] && ps "$entr_pid" &> /dev/null; then
        kill "$entr_pid"
      fi
      tmux set-option -gu @tmux-autoreload-pid &
    } || true
    return $code
  }

  trap 'onexit' EXIT
  tmux set-option -g @tmux-autoreload-pid $$

  entr -np tmux source "${config_files[@]}" ';' run-shell "$self -m 'Reloaded tmux.conf'" 2>&1 <<< "${config_files[@]}" &
  entr_pid=$!
  wait
}

main "$@"
