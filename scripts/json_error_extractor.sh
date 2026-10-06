#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <log-file>" >&2
    exit 1
fi

log_file="$1"

if [[ ! -f "$log_file" ]]; then
    echo "error: file not found: $log_file" >&2
    exit 1
fi

jq '[.[] | select(.level == "ERROR") | {
    timestamp,
    message,
    trace_id
}]' "$log_file"
