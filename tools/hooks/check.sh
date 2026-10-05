#!/usr/bin/env bash
# Contribution checks shared by pre-commit and GitHub Actions.
#   check.sh branch     local commit and pre-push
#   check.sh message    local commit-msg, file path in $2
#   check.sh commits    CI, every subject on the pull request
#   check.sh pr         CI, branch + title + exactly one Closes line
set -euo pipefail

usage() {
    echo "usage: check.sh branch|message|commits|pr" >&2
    exit 2
}

is_epic_branch() {
    [[ "$1" =~ ^epic[0-9]+$ ]]
}

is_task_branch() {
    [[ "$1" =~ ^task/[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

is_mentor_branch() {
    [[ "$1" =~ ^mentor/[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

valid_subject() {
    local subject=$1

    if [[ ${#subject} -gt 100 ]]; then
        return 1
    fi
    if [[ "$subject" == *. ]]; then
        return 1
    fi
    [[ "$subject" =~ ^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?:[[:space:]][^[:space:]].* ]]
}

print_subject_help() {
    cat >&2 <<'EOF'
Use: type(scope): subject
Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
Example: feat: add nginx status analyzer
The subject is 100 characters or fewer and does not end with a period.
EOF
}

cmd_message() {
    local file=${1:-}
    local subject=""
    local line

    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "ERROR: commit message file missing." >&2
        exit 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -z "$line" || "$line" == '#'* ]]; then
            continue
        fi
        subject=$line
        break
    done <"$file"

    if [[ -z "$subject" ]]; then
        echo "ERROR: commit subject is empty." >&2
        print_subject_help
        exit 1
    fi

    if ! valid_subject "$subject"; then
        echo "ERROR: commit subject is not a Conventional Commit: $subject" >&2
        print_subject_help
        exit 1
    fi
}

cmd_branch() {
    local branch

    if ! branch=$(git symbolic-ref --short HEAD 2>/dev/null); then
        exit 0
    fi

    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
        exit 0
    fi

    if is_epic_branch "$branch" || is_task_branch "$branch" || is_mentor_branch "$branch"; then
        exit 0
    fi

    cat >&2 <<EOF
Branch name is not allowed: $branch

Epic integration branches:
  epic<number>
  Example: epic1

Mentor branches:
  mentor/<slug>
  Example: mentor/implementation

Task branches, one per task card:
  task/<number>-short-slug
  Example: task/3-kanban-board-ui-layout

The task number is the digits on the card (INT-<number>).
The slug is lowercase words separated by hyphens.
Do not rename a task branch after its pull request is opened.
EOF
    exit 1
}

cmd_commits() {
    local base=${BASE:-}
    local head=${HEAD:-HEAD}
    local subject
    local failed=0

    if [[ -z "$base" ]]; then
        echo "ERROR: BASE is required (the pull request base SHA)." >&2
        exit 1
    fi

    while IFS= read -r subject; do
        if [[ -z "$subject" ]]; then
            continue
        fi
        if [[ "$subject" == Merge\ * ]]; then
            echo "ERROR: merge commits are not allowed: $subject" >&2
            echo "Rebase the branch onto main." >&2
            failed=1
            continue
        fi
        if ! valid_subject "$subject"; then
            echo "ERROR: commit subject is not a Conventional Commit: $subject" >&2
            failed=1
        fi
    done < <(git log --reverse --format=%s "${base}..${head}")

    if [[ "$failed" -ne 0 ]]; then
        print_subject_help
        exit 1
    fi
}

cmd_pr() {
    local branch=${HEAD_REF:-}
    local title=${PR_TITLE:-}
    local body=${PR_BODY:-}
    local count=0
    local task_line=""
    local line
    local rest
    local number
    local token
    local seen=" "
    local closes_re='Closes INT-([0-9]+)'
    local branch_number
    local task_number
    local base=${BASE_REF:-}

    if is_epic_branch "$branch" || is_mentor_branch "$branch"; then
        if ! valid_subject "$title"; then
            echo "ERROR: pull request title is not a Conventional Commit: $title" >&2
            print_subject_help
            exit 1
        fi
        echo "Branch $branch is allowed. Task links are checked on task/* pull requests."
        exit 0
    fi

    if ! is_task_branch "$branch"; then
        cat >&2 <<EOF
ERROR: branch '$branch' is not a task branch.
Contributors open pull requests from task/<number>-short-slug.
Example: task/3-kanban-board-ui-layout
EOF
        exit 1
    fi

    if [[ -n "$base" ]] && ! is_epic_branch "$base"; then
        cat >&2 <<EOF
ERROR: open this pull request against an epic branch such as epic1.
It currently targets $base.
EOF
        exit 1
    fi

    if ! valid_subject "$title"; then
        echo "ERROR: pull request title is not a Conventional Commit: $title" >&2
        print_subject_help
        exit 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        rest=$line
        while [[ "$rest" =~ $closes_re ]]; do
            number=${BASH_REMATCH[1]}
            token="Closes INT-${number}"
            case "$seen" in
                *" ${token} "*) ;;
                *)
                    seen="${seen}${token} "
                    count=$((count + 1))
                    task_line=$token
                    ;;
            esac
            rest=${rest#*"$token"}
        done
    done <<<"$body"

    if [[ "$count" -eq 0 ]]; then
        cat >&2 <<'EOF'
ERROR: pull request description must contain exactly one line of the form:
  Closes INT-<number>
The words and the INT- prefix are case-sensitive.
EOF
        exit 1
    fi

    if [[ "$count" -ne 1 ]]; then
        echo "ERROR: one pull request per task. Found $count task links:" >&2
        echo "$seen" >&2
        exit 1
    fi

    branch_number=${branch#task/}
    branch_number=${branch_number%%-*}
    task_number=${task_line#Closes INT-}

    if [[ "$task_number" != "$branch_number" ]]; then
        cat >&2 <<EOF
ERROR: branch task/$branch_number does not match $task_line.
The wrong number links this work to someone else's task.
Merging would mark that task complete.
EOF
        exit 1
    fi

    echo "Contribution rules passed for task/$branch_number ($task_line)."
}

case "${1:-}" in
    branch)
        cmd_branch
        ;;
    message)
        cmd_message "${2:-}"
        ;;
    commits)
        cmd_commits
        ;;
    pr)
        cmd_pr
        ;;
    *)
        usage
        ;;
esac
