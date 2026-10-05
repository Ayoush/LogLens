# hooks

`check.sh` is the single contribution checker. Pre-commit and GitHub Actions both call it so the rules cannot drift into two implementations.

```bash
bash tools/hooks/check.sh branch
bash tools/hooks/check.sh message .git/COMMIT_EDITMSG
bash tools/hooks/check.sh commits    # requires BASE and HEAD
bash tools/hooks/check.sh pr         # requires HEAD_REF, PR_TITLE, PR_BODY; BASE_REF when the head is a task branch
```

| Subcommand | Caller | Pass condition |
|---|---|---|
| `branch` | pre-commit and pre-push | Detached HEAD, `main`, `master`, `epic<number>`, `mentor/<slug>`, or `task/<number>-short-slug` |
| `message` | commit-msg hook | The subject line is a Conventional Commit |
| `commits` | CI job `commits` | Every subject in `BASE..HEAD` is a Conventional Commit, and none are merge commits |
| `pr` | CI job `contribution-rules` | Epic or mentor head: Conventional Commit title. Task head: title, exactly one `Closes INT-<number>` matching the branch, and the pull request targets `epic<number>` |

The script must stay executable (`chmod +x tools/hooks/check.sh`). The shebang check in pre-commit fails the commit otherwise. CI invokes it with `bash`, so GitHub does not depend on the mode bit, but reviewers will still see the hook failure locally.

Style is the repo shell style: 4-space indent, ShellCheck, shfmt `-i 4 -ci -bn`. If you change the allowed commit types, update the regex in `valid_subject` and the table in the root README in the same pull request. The local hook and the CI jobs both call this script, so the rule stays in one place.
