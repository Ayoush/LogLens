#!/usr/bin/env bash

if [[ ! -f "$1" ]]; then
    echo "error: log file not found: $1" >&2
    exit 1
fi

awk '{print $8}' "$1" | sort | uniq -c | sort -rn
