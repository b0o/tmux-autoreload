#!/bin/bash

# Copyright (C) 2020-2021 Maddison Hellstrom <https://github.com/b0o>, MIT License.

set -Eeuo pipefail
if [[ ${BASH_VERSINFO[0]} -ge 5 || (${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -ge 4) ]]; then
  shopt -s inherit_errexit
fi

declare -g self prog basedir reporoot
self="$(readlink -e "${BASH_SOURCE[0]}")"
prog="$(basename "$self")"
basedir="$(realpath -m "$self/..")"
reporoot="$(realpath -m "$basedir/..")"

# gendocs configuration {{{

declare -g main="${reporoot}/tmux-autoreload.tmux"

declare -gA targets=(
  [readme]="$reporoot/README.md"
)

declare -gi copyright_start=2021

function target_readme() {
  section -s USAGE -c <<< "$("$main" -h 2>&1)"
  section -s LICENSE << EOF
&copy; ${copyright_start}$( (($(date +%Y) == copyright_start)) || date +-%Y) Maddison Hellstrom

Released under the MIT License.
EOF
}

# }}}

declare -gA sections

function section() {
  local section
  local -i code=0
  local lang

  local opt OPTARG
  local -i OPTIND
  while getopts "s:cC:" opt "$@"; do
    case "$opt" in
    s)
      section="$OPTARG"
      ;;
    c)
      code=1
      ;;
    C)
      code=1
      lang="$OPTARG"
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  local -a lines=('')

  if [[ $code -eq 1 ]]; then
    lines+=('```'"${lang:-}" '')
  fi

  mapfile -tO ${#lines[@]} lines

  if [[ $code -eq 1 ]]; then
    lines+=('' '```')
  fi

  sections["$section"]="$(printf '%s\n' "${lines[@]}")\n"
}

function regen_section() {
  local section="$1"
  local content="${sections[$section]}"
  awk < "$target" -v "section=$section" -v "content=$content" '
    BEGIN {
      d = 0
    }

    {
      if (match($0, "^<!-- " section " -->$")) {
        d = 1
        print $0
        print content
        next
      }
      if (match($0, "^<!-- /" section " -->$")) {
        d = 0
        print $0
        next
      }
    }

    d == 0 {
      print $0
    }
  '
}

function main() {
  local opt OPTARG
  local -i OPTIND
  while getopts "h" opt "$@"; do
    case "$opt" in
    h)
      echo "usage: $prog [opt].. [target].." >&2
      return 0
      ;;
    \?)
      return 1
      ;;
    esac
  done
  shift $((OPTIND - 1))

  local -a targets_selected=("${!targets[@]}")

  if [[ $# -gt 0 ]]; then
    targets_selected=("$@")
  fi

  local t target
  for t in "${targets_selected[@]}"; do
    [[ -v "targets[$t]" ]] || {
      echo "unknown target: $t" >&2
      return 1
    }
    target="${targets["$t"]}"
    [[ -e "$target" ]] || {
      echo "target file not found: $target" >&2
      return 1
    }
    sections=()
    "target_${t}" || {
      echo "unknown target: $t"
      return 1
    }
    local s
    for s in "${!sections[@]}"; do
      regen_section "$s" > "${target}_"
      mv "${target}_" "$target"
    done
  done
}

main "$@"
