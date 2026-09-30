# shell

The Unix toolkit. Boring on purpose: fast answers from `grep`, `awk`, `sed`, `sort`, and `jq` before anyone reaches for the Python CLI.

| Future file | Role |
|---|---|
| `loglens.sh` | Subcommands: `top-ips`, `status`, `5xx-per-min`, `top-paths`, `slowest`, `user-agents`, `ssh-fails`, `ssh-users`, `journal-errors`, `restarts`, `big-files`, `window` |
| `permaudit.sh` | World-writable paths, setuid, ACLs, sudo membership, sensitive modes, umask |
| `lib/common.sh` | Shared helpers sourced by both scripts |

Run the permission auditor only against the lab directory, not against arbitrary system paths.

ShellCheck and shfmt cover everything in this tree. Support rotated logs, including gzip, where the command claims to. A useful pattern is `zcat -f access.log*`.

The starter scripts in `scripts/` are allowed to stay small and single-purpose. Promote a behavior into `loglens.sh` when a second caller needs it.
