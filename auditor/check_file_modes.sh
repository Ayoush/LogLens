#!/usr/bin/env bash

# -e exit on command failure
# -u error on unset variables
# -o pipefail fail pipeline on first failure
set -euo pipefail

print_usage() {
    echo "Usage: $(basename "$0") [--ignore-symlinks] <target-directory>" >&2
}

IGNORE_SYMLINKS=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ignore-symlinks)
            IGNORE_SYMLINKS=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo "ERROR: unknown option '$1'" >&2
            print_usage
            exit 2
            ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
                shift
            else
                echo "ERROR: unexpected extra argument '$1'" >&2
                print_usage
                exit 2
            fi
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo "ERROR: target directory is required" >&2
    print_usage
    exit 2
fi

if [[ ! -e "$TARGET" ]]; then
    echo "ERROR: target path '$TARGET' does not exist." >&2
    exit 2
fi

if [[ ! -d "$TARGET" ]]; then
    echo "ERROR: target path '$TARGET' is not a directory." >&2
    exit 2
fi

unsafe_found=0

echo "Scanning '$TARGET' for unsafe file modes..."
echo ""

declare -a suid_records=()
declare -a sgid_records=()
declare -a ww_files=()
declare -a ww_dirs=()

# Determine file predicate based on --ignore-symlinks flag
declare -a file_type
if [[ "$IGNORE_SYMLINKS" == true ]]; then
    file_type=( "-type" "f" )
else
    file_type=( "(" "-type" "f" "-o" "-type" "l" ")" )
fi

# Single-pass filesystem traversal: evaluates all 4 conditions independently
# via GNU find comma operator (,) and formats directly with -printf to eliminate
# redundant tree walks and per-file stat process forking.
while IFS=$'\t' read -r category mode symbolic ownership path; do
    [[ -z "$category" ]] && continue
    record="    mode: ${mode} (${symbolic})  owner: ${ownership}  path: ${path}"
    case "$category" in
        SUID)
            suid_records+=("$record")
            ;;
        SGID)
            sgid_records+=("$record")
            ;;
        WW_FILE)
            ww_files+=("$record")
            ;;
        WW_DIR)
            ww_dirs+=("$record")
            ;;
    esac
done < <(find "$TARGET" \
    \( "${file_type[@]}" -perm -4000 -printf 'SUID\t%m\t%M\t%u:%g\t%p\n' \) , \
    \( "${file_type[@]}" -perm -2000 -printf 'SGID\t%m\t%M\t%u:%g\t%p\n' \) , \
    \( "${file_type[@]}" -perm -0002 -printf 'WW_FILE\t%m\t%M\t%u:%g\t%p\n' \) , \
    \( -type d -perm -0002 ! -perm -1000 -printf 'WW_DIR\t%m\t%M\t%u:%g\t%p\n' \) 2>/dev/null || true)

if (( ${#suid_records[@]} > 0 )); then
    echo "[CRITICAL] SUID files detected (Set User ID bit active):"
    printf '%s\n' "${suid_records[@]}"
    echo ""
    unsafe_found=1
fi

if (( ${#sgid_records[@]} > 0 )); then
    echo "[WARNING] SGID files detected (Set Group ID bit active):"
    printf '%s\n' "${sgid_records[@]}"
    echo ""
    unsafe_found=1
fi

if (( ${#ww_files[@]} > 0 )); then
    echo "[CRITICAL] World-writable files detected (other has write permission):"
    printf '%s\n' "${ww_files[@]}"
    echo ""
    unsafe_found=1
fi

if (( ${#ww_dirs[@]} > 0 )); then
    echo "[CRITICAL] World-writable directories WITHOUT sticky bit detected:"
    printf '%s\n' "${ww_dirs[@]}"
    echo ""
    unsafe_found=1
fi

if [[ "$unsafe_found" -ne 0 ]]; then
    echo "AUDIT FAILED: Unsafe file modes were detected in '$TARGET'."
    exit 1
fi

echo "OK: No unsafe file permissions detected in '$TARGET'."
exit 0
