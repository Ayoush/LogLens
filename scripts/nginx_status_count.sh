#!/bin/bash

file="$1"

if [ ! -f "$file" ]; then
    echo "Error: file not found" >&2
    exit 1
fi

awk '{print $9}' "$file" | sort | uniq -c | sort -rn | awk '{print $2, $1}'