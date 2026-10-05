#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 LOG_FILE" >&2
    exit 2
}

if [[ "$#" -ne 1 ]]; then
    usage
fi

logpath="$1"

if [[ -d "$logpath" ]]; then
    echo "path is a directory: $logpath" >&2
    exit 1
fi

if [[ ! -f "$logpath" ]]; then
    echo "no such file: $logpath" >&2
    exit 1
fi

if [[ ! -r "$logpath" ]]; then
    echo "cannot read file: $logpath" >&2
    exit 1
fi

awk '$9 ~ /^[1-5][0-9][0-9]$/ {print $9}' "$logpath" \
    | sort \
    | uniq -c \
    | sort -rn \
    | awk '{print $2, $1}'
