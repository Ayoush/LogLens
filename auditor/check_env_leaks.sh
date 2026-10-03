#!/usr/bin/env bash

# -e exit when a command fails
# -u error on unset variables
# -o pipefail fail if any command in a pipeline fails
set -euo pipefail

if [[ $# -ne 1 ]]; then # checks if exactly one argument is passed
    echo "ERROR: exactly one path is required" >&2
    exit 2
fi

if [[ ! -e "$1" ]]; then # checks if the path is valid
    echo "ERROR: the specified path does not exist." >&2
    exit 2
fi

TARGET="$1"

SK_REGEX="(^|[^[:alnum:]_-])(sk[-_])([[:alnum:]_-]{16,})([[:alnum:]_-]{4})"
PWD_REGEX="((password|passwd|secret|token|api[_-]?key)[\"']?[[:space:]]*[=:][[:space:]]*)(\"([^\"\\\\]|\\\\.)*\"|'[^']*'|[^[:space:]\"']+)"

mask() {
    sed -E \
        -e "s/$SK_REGEX/\1\2****\4/gI" \
        -e "s/$PWD_REGEX/\1****/gI"
}

if grep -rnIEi -e "$SK_REGEX" -e "$PWD_REGEX" "$TARGET" | mask; then
    path_status=0
else
    path_status=$?
fi

if env | grep -nEi -e "$SK_REGEX" -e "$PWD_REGEX" | mask; then
    env_status=0
else
    env_status=$?
fi

# For path and env status
# 0: at least one secret found
# 1: no secrets found
# 2: grep had an error

if [[ $path_status -gt 1 || $env_status -gt 1 ]]; then
    exit 2
fi

if [[ $path_status -eq 0 || $env_status -eq 0 ]]; then
    exit 1
fi

exit 0
