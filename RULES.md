# Rules for everyone

Follow these so work is tracked, reviewed, and credited, and so the repository stays formatted the same way no matter who commits.

A wrong branch name or a missing task link does not produce a loud error from the tracker. The link simply never happens. CI rejects that pull request so the mistake is visible before merge.

Read this file before the first commit. Install the hooks in [Install the checks](#install-the-checks) once per clone. After that, `git commit` runs the checks for you.

## Get these wrong and the automation silently stops working

1. **Put `Closes INT-<number>` in the pull request description.** This is how the pull request is linked to the task. Without that exact phrase, the pull request is not connected to anything.
2. **Name the branch `task/<number>-short-slug`.** Example: `task/3-kanban-board-ui-layout`. This is the backup link, and it is a checked rule.
3. **Use the task number printed on the task card.** That number looks like `INT-<number>`. A wrong number links the work to someone else's task, and merging marks that task complete.
4. **Open one pull request per task.** If a pull request covers two tasks, only one gets linked. The other is never tracked.

## Also worth knowing

- Link the GitHub account before joining. Pull requests can only be credited to a linked account.
- Do not rename the branch after opening the pull request. The link is resolved when the pull request is opened.
- When the pull request is merged, the task moves to Done automatically.
- The bot posts a review on every pull request. It checks that task's acceptance criteria one by one and suggests what to read. It never blocks the merge. A failing CI check does block the merge. Those are different signals.

## Branch names

| Who | Branch | Example |
|---|---|---|
| Integration | `main` | `main` |
| Epic owner | `epic<number>` | `epic1`, `epic2` |
| Everyone else | `task/<number>-short-slug` | `task/1-nginx-status-count` |

Epic branches are the long-lived lines for an epic. Only the epic owner creates `epic1`, `epic2`, and so on. Collaborators do not create epic branches and do not push directly to them.

Task branches are one per task card:

```text
task/<number>-short-slug
```

- `<number>` is the digits from `INT-<number>` on the card. The branch does not contain the `INT-` prefix.
- `<short-slug>` is lowercase words separated by single hyphens. It describes the change.
- Digits may appear inside a slug word. The slug does not start or end with a hyphen.
- Start from the epic branch you are working in. Open the pull request back into that epic branch. Example: `task/1-nginx-status-count` into `epic1`.

These names fail the check:

```text
feature/nginx-status
epic-1
task/INT-1-nginx-status
task/1_nginx_status
Task/1-nginx-status
```

`git commit` and `git push` reject any other name. `main` is allowed. `epic1` is allowed as a name. GitHub, not the local hook, is what stops other people from creating or pushing epic branches. See [Epic owner setup](#epic-owner-setup).

## Pull requests

The description contains this phrase once, with the real task number:

```text
Closes INT-1
```

Capitalization matters. `closes int-1` is a different string. The digits must be the same digits as the branch, so `task/1-nginx-status-count` pairs with `Closes INT-1`.

A second `Closes INT-<number>` line means the pull request is trying to close two tasks. Split it.

The pull request title is a Conventional Commit, because squash merge uses the title as the commit subject:

```text
feat: count nginx status codes
```

GitHub fills in `.github/pull_request_template.md` on a new pull request. Replace `NUMBER` before opening it. Open the pull request against the epic branch (`epic1`, `epic2`), not against `main`.

## A complete example

Task card: `INT-1`, count Nginx status codes. The work belongs to epic 1.

```bash
git checkout epic1
git pull
git checkout -b task/1-nginx-status-count
```

Commit subjects along the way:

```text
feat: count nginx status codes
test: cover missing access log
```

Pull request title:

```text
feat: count nginx status codes
```

Pull request description includes:

```text
Closes INT-1
```

After that, leave the branch name alone. Open the pull request into `epic1`. Merge with squash. The task moves to Done.

## Commit messages

Every commit subject is a Conventional Commit:

```text
<type>(<optional-scope>): <imperative subject>
```

| Type | Use it for |
|---|---|
| `feat` | User-visible behavior |
| `fix` | A defect |
| `docs` | Documentation only |
| `style` | Formatting that does not change behavior |
| `refactor` | Restructuring that does not change behavior |
| `perf` | A measured performance change |
| `test` | Tests only |
| `build` | Build or dependency setup |
| `ci` | GitHub Actions or hooks |
| `chore` | Maintenance that fits none of the above |
| `revert` | Reverting an earlier commit |

Accepted:

```text
feat: add nginx status analyzer
fix: handle missing log file
docs: describe the parser protocol
refactor(parsers): share one record type
chore: update CI workflow
```

Rejected by the commit-msg hook and again by CI:

```text
Epic 1: Created the base setup
updated stuff
WIP
Feat: Add analyzer
feat: add analyzer.
```

Rules for the subject line:

- Lowercase type, from the table above.
- Optional scope in parentheses, lowercase (`feat(parsers): ...`).
- Colon, then a single space, then an imperative subject.
- 100 characters or fewer.
- No trailing period.
- A breaking change may use `feat!:` or `feat(cli)!:`.

## Formatting

Everyone's editor is expected to produce the same bytes.

| Kind | Rule | Enforced by |
|---|---|---|
| All text | UTF-8, LF line endings, file ends with a newline | `.editorconfig`, pre-commit |
| Python | Ruff format and lint, line length 100, double quotes | `.pre-commit-config.yaml`, `pyproject.toml` |
| Shell | 4-space indent, ShellCheck clean | shfmt, ShellCheck |
| YAML, JSON, TOML | 2-space indent, valid syntax | EditorConfig, pre-commit |
| Secrets | Private keys and `.env` stay local | `detect-private-key`, `.gitignore` |

Python style is configured once in `pyproject.toml`. The pre-commit hook runs the same Ruff version pinned in `.pre-commit-config.yaml`. When you bump Ruff, change both pins in the same pull request.

EditorConfig is the cross-editor contract. `.vscode/settings.json` turns format-on-save on for Python and shell in Cursor and VS Code. Other editors should honor `.editorconfig`.

If a hook rewrites a file, the commit stops. That is success of the formatter, not a broken repository. Stage the rewritten file and commit again:

```bash
git add tools/hooks/check.sh
git commit -m "chore: add the epic 1 base setup for task work"
```

Use your own subject. The example above is only the shape.

## Install the checks

The checks do not run on `git commit` until the hooks are installed in that clone. Run this once, from the repository root:

```bash
chmod +x tools/hooks/check.sh
uv tool install pre-commit
pre-commit install
pre-commit run --all-files
```

`uv tool install` puts `pre-commit` on your user PATH. If you already manage pre-commit another way, use that install and still run `pre-commit install`. That one command registers the commit, commit-msg, and pre-push hooks, because `.pre-commit-config.yaml` sets `default_install_hook_types`.

| Hook | When | What it does |
|---|---|---|
| trailing whitespace, final newline, LF | every commit | stops noisy diffs |
| YAML, TOML, JSON, merge conflicts | every commit | catches broken config before push |
| private-key and large-file checks | every commit | keeps secrets and log dumps out |
| Ruff lint `--fix` and Ruff format | every commit | Python stays on one style |
| shfmt and ShellCheck | every commit | shell stays on one style |
| `tools/hooks/check.sh branch` | every commit and every push | branch is `main`, `epic<number>`, or `task/<number>-short-slug` |
| Conventional Commit check | every commit message | subject matches the types above |

CI runs the same formatting hooks, then checks every commit on the pull request, the pull request title, the branch name, and the single `Closes INT-<number>` line. Skipping a local hook still fails the pull request.

## What CI checks

| Job | Workflow | Required before merge |
|---|---|---|
| `formatting` | `.github/workflows/ci.yml` | pre-commit on every file |
| `python` | `.github/workflows/ci.yml` | `mypy --strict`, pytest when `tests/test_*.py` exists |
| `commits` | `.github/workflows/ci.yml` | every commit subject, pull-request only |
| `contribution-rules` | `.github/workflows/contribution-rules.yml` | branch, title, task link, and epic base for task pull requests |

On a task pull request, `contribution-rules` passes only when all of these are true:

- The head branch matches `task/<number>-short-slug`.
- The base branch is an epic branch, such as `epic1`.
- The title is a Conventional Commit.
- The body contains exactly one `Closes INT-<number>`, and that number matches the branch.

## Review

- The task bot comments on acceptance criteria. Read it. It does not block merge.
- A red required check does block merge. Fix the branch, the `Closes` line, the commit subjects, or the formatting, then push again.
- Review the diff for behavior, tests, and log safety. Formatting comments are already handled by the hooks.
- Keep the pull request to one task so the review and the tracker agree.

## Log data and secrets

- Generate practice logs locally. Commit only sanitized fixtures under `tests/fixtures/`.
- `data/raw_logs/` and `eval/windows/` are gitignored except for their READMEs.
- Copy `.env.example` to `.env` for the LLM key. `.env` is gitignored.
- Set a provider spend limit before any paid extraction call.

## Epic owner setup

Collaborators skip this section. It is how the epic owner limits `epic1` and `epic2` to themselves.

The local hook accepts an `epic<number>` name for every clone. It cannot tell people apart. GitHub can. After `gh auth login` as the account that owns the repository, run this once:

```bash
actor_id="$(gh api user --jq .id)"
repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

gh api --method POST "repos/${repo}/rulesets" --input - <<EOF
{
  "name": "epic-branches",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [
    {"actor_id": ${actor_id}, "actor_type": "User", "bypass_mode": "always"}
  ],
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/epic*"],
      "exclude": []
    }
  },
  "rules": [
    {"type": "creation"},
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
EOF
```

That login must be the epic owner. `actor_id` is whatever user `gh` is logged in as. Add another GitHub user to `bypass_actors` only if that person should also create epic branches.

Pushing `epic1` can happen before or after the ruleset. Once the ruleset is active, the owner can still push `epic*` because that user is on the bypass list. Everyone else updates the epic branch by pull request.

After the CI jobs have run once on GitHub, also protect `main`:

- Require a pull request before merging.
- Require the four checks: `formatting`, `python`, `commits`, `contribution-rules`.
- Squash merge, and use the pull request title as the squash commit message.
- Disallow force-push to `main`.

GitHub only offers a check name it has already seen, so turn that protection on after the workflows have run at least once.
