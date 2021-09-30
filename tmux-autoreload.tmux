#!/usr/bin/env bash

# Automatically reloads your tmux configuration files on change.
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

function usage() {
  cat <<EOF
Usage: $prog [-f] [OPT...]
  Automatically reloads your tmux configuration files on change.

Options
  -h      Display usage information.
  -v      Display $name version and copyright information.
  -f      Run in foreground (do not fork).
  -k      Kill the running $name instance.
  -s      Show $name status

Installation
  To install $name with TPM (https://github.com/tmux-plugins/tpm), add the
  following line to the end of your tmux configuration file:
      set-option -g @plugin '$repo_short'

  If you don't use a plugin manager, git clone $name to the location of your
  choice and run it directly:
      run-shell "/path/to/$name/$prog"

  Once installed, you should be good to go unless you use non-standard
  configuration file paths or want to customize how $name behaves.

Configuration file paths
  If your config file is at a non-standard location or if you have multiple,
  specify them in @$name-configs, separated by commas:
    set-option -g @$name-configs '/path/to/configs/a.conf,/path/to/configs/b.conf'

Entrypoints
  Normally, $name will source whichever file changed. If you wish to
  source a specific set of files when any configuration file changes, use
  @$name-entrypoints:
    set-option -g @$name-entrypoints '/path/to/entrypoint.conf'

  You can specify multiple entrypoints separated by commas. All entrypoints
  will be sourced when any watched file changes.

  Set @$name-entrypoints to 1 to use the standard tmux configuration
  files as entrypoints, usually /etc/tmux.conf and ~/.tmux.conf. You can see
  these files with:
    tmux display-message -p "#{config_files}".

  Entrypoint Notes:
  - If entrypoints are configured, a changed file itself will not necessarily
    be reloaded unless it's an entrypoint or is sourced by an entrypoint.

  - Entrypoints will not be watched unless they're a standard tmux
    configuration file like ~/.tmux.conf or are included in @$name-configs.

Other Options
  @$name-quiet 0|1 (Default: 0)
    If set to 1, $name will not display messages

EOF
}

function usage_version() {
  cat <<EOF
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
  if [[ "$(tmux show-option -gv "@$name-quiet")" == "1" ]]; then
    return 0
  fi
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

function get_base_configs() {
  tmux display-message -p "#{config_files}" | tr ',' '\n' | sort -u
}

function get_user_configs() {
  tmux show-option -gv "@$name-configs" | tr ',' '\n' | sort -u
}

function get_entrypoints() {
  local entrypoints
  entrypoints="$(tmux show-option -gv "@$name-entrypoints")"
  if [[ -z "$entrypoints" || "$entrypoints" == "0" ]]; then
    return 0
  fi
  if [[ "$entrypoints" == "1" ]]; then
    get_base_configs
  else
    echo "$entrypoints" | tr ',' '\n'
  fi
}

function get_instance() {
  local -i instance_pid
  instance_pid="$(tmux show-options -gv "@$name-pid")"
  if [[ "$instance_pid" -gt 0 ]] && ps "$instance_pid" &>/dev/null; then
    echo "$instance_pid"
    return 0
  fi
  return 1
}

function reload() {
  local -a entrypoints
  mapfile -t entrypoints < <(get_entrypoints)
  if [[ ${#entrypoints[@]} -eq 0 ]]; then
    entrypoints=("$@")
  fi
  if msg="$(tmux source-file "${entrypoints[@]}")"; then
    display_message "Reloaded $(
      printf '%s\n' "${entrypoints[@]}" | xargs -n1 basename | tr '\n' ',' | sed 's/,$/\n/; s/,/, /g'
    )"
  else
    display_message -d 0 "#[fg=white,bg=red,bold]ERROR: $msg"
  fi
}

function onexit() {
  local -i code=$?
  local -i entr_pid=$1
  display_message "$name exited with code $code" || true
  if [[ -v entr_pid && $entr_pid -gt 1 ]] && ps "$entr_pid" &>/dev/null; then
    kill "$entr_pid" || true
  fi
  tmux set-option -gu "@$name-pid" &
  return "$code"
}

function kill_instance() {
  local -i instance_pid
  if instance_pid="$(get_instance)"; then
    kill "$instance_pid"
    return $?
  fi
  echo "$name -k: kill failed: no instance found" >&2
  return 1
}

function get_status() {
  local -i instance_pid
  if instance_pid="$(get_instance)"; then
    echo "running: $instance_pid"
    return 0
  fi
  echo "not running"
  return 1
}

function main() {
  if ! [[ "${1:-}" =~ ^-[hvfksr]$ ]]; then
    "$self" -f "$@" &>/dev/null &
    disown
    exit $?
  fi

  local opt OPTARG
  local -i OPTIND
  while getopts "hvfksr:" opt "$@"; do
    case "$opt" in
    h)
      usage
      return 0
      ;;
    v)
      usage_version
      return 0
      ;;
    f)
      # Silently ignore -f
      ;;
    k)
      kill_instance
      return
      ;;
    s)
      get_status
      return
      ;;
    r)
      reload "$OPTARG"
      return
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  if get_instance &>/dev/null; then
    return 0
  fi

  command -v entr &>/dev/null || {
    echo "Command not found: entr" >&2
    display_message -d 0 "Failed to start $name: Command not found: entr"
    return 1
  }

  tmux set-option -g "@$name-pid" $$

  # shellcheck disable=2016
  entr -np sh -c '"$0" -r "$1"' "$self" /_ <<<"$(printf '%s\n' "$(get_base_configs)" "$(get_user_configs)")" &
  # shellcheck disable=2064
  trap "onexit $!" EXIT
  wait
}

main "$@"
