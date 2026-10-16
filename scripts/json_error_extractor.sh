#!/usr/bin/env bash

# Guard 1: Check that a file argument was provided.
if [[ $# -eq 0 ]]; then
    echo "Error: Missing input file." >&2
    echo "Usage: $0 <json-log-file>" >&2
    exit 1
fi

# Guard 2: Check that the argument points to a regular file.
if [[ ! -f "$1" ]]; then
    echo "Error: File does not exist or is not a regular file: $1" >&2
    exit 1
fi

# Extract ERROR logs and output the required fields as a JSON array.
jq '[.[] | select(.level == "ERROR") | {
    timestamp,
    message,
    trace_id
}]' "$1"
