# .github

GitHub-facing project files. Nothing in here runs on a laptop until a pull request or a push to `main`.

| Path | Role |
|---|---|
| `pull_request_template.md` | Starts every pull request with one `Closes INT-NUMBER` line. Replace `NUMBER` before opening. |
| `workflows/ci.yml` | Formatting, typecheck, tests, and commit subjects. |
| `workflows/contribution-rules.yml` | Branch name, pull request title, and the single task link. |

Branch protection is a GitHub setting, not a file. After the four check names have run once (`formatting`, `python`, `commits`, `contribution-rules`), protect `main`, and add the epic-branch ruleset described in the root README. That ruleset is what limits `epic1` and `epic2` to the people who should create them.
