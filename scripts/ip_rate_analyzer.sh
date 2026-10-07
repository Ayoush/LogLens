#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <access.log> <threshold>" >&2
    exit 1
fi

LOG_FILE="$1"
THRESHOLD="$2"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "error: file not found: $LOG_FILE" >&2
    exit 1
fi

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "error: threshold must be a non-negative integer: $THRESHOLD" >&2
    exit 1
fi

awk '{print $1}' "$LOG_FILE" \
    | sort \
    | uniq -c \
    | awk -v threshold="$THRESHOLD" '$1 > threshold {print $1, $2}' \
    | sort -rn
