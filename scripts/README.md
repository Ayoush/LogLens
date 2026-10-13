# scripts

The first three tasks. Each script is small, executable, and ShellCheck-clean. They are the pieces that later fold into `shell/loglens.sh`.

| Task | Script | Input |
|---|---|---|
| INT-1 | `nginx_status_count.sh` | `data/raw_logs/access.log` |
| INT-2 | `json_error_extractor.sh` | `data/raw_logs/app.json` |
| INT-3 | `ip_rate_analyzer.sh` | access log plus a count threshold |

Acceptance criteria for each task are in the root README under "Starter tasks".

Conventions once the files exist:

- Bash, `set -euo pipefail`.
- 4-space indent, so shfmt does not rewrite them.
- A missing input file exits `1` and writes the error to stderr.
- No network, no LLM, no dependency beyond the usual Unix tools (`awk`, `sort`, `uniq`, `jq`).

Git hooks live in `tools/hooks/`, not here. This directory stays reserved for log commands.
