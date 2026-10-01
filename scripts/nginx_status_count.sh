#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <log-file>" >&2
    exit 1
fi

log_file="$1"

if [[ ! -f "$log_file" ]]; then
    echo "Error: file not found: $log_file" >&2
    exit 1
fi

awk '{print $9}' "$log_file" |
    sort |
    uniq -c |
    sort -rn |
    awk '{print $2, $1}'
