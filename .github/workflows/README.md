# Workflows

Both workflows use least-privilege `contents: read`. They cancel an older run on the same ref when a new push arrives.

## `ci.yml`

Runs on every pull request and on pushes to `main`.

| Job | What a failure means |
|---|---|
| `formatting` | pre-commit would have rewritten or rejected the diff. Run `pre-commit run --all-files` locally and commit the result. |
| `python` | `mypy --strict` failed, or pytest failed once `tests/test_*.py` exists. |
| `commits` | A subject on the branch is not a Conventional Commit, or the branch contains a merge commit. Rebase onto `main` and reword. |

The `formatting` job checks out a detached HEAD, so the local branch-name hook exits cleanly there. Branch names are judged by `contribution-rules.yml`, which sees `github.head_ref`.

## `contribution-rules.yml`

Runs when a pull request is opened, edited, synchronized, reopened, or marked ready.

The job fails unless all of these are true:

- The head branch is `epic<number>` or `mentor/<slug>`, or it is `task/<number>-short-slug` and the base branch is an epic branch.
- The title is a Conventional Commit, because squash merge uses it as the commit subject.
- A task pull request body contains exactly one distinct `Closes INT-<number>` phrase, and that number matches the branch.
- An epic pull request is an integration branch. It does not carry a single task link.

Editing the description re-runs the check. Renaming the branch after the pull request is open breaks the tracker link even if you then fix the name, so open the pull request with the final branch name.
