#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="$1"
THRESHOLD="$2"

awk '{print $1}' "$LOG_FILE" \
    | sort \
    | uniq -c \
    | awk -v threshold="$THRESHOLD" '$1 > threshold {print $1, $2}' \
    | sort -rn
