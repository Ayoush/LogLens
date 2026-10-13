# shell/lib

Shared shell helpers for `loglens.sh` and `permaudit.sh`.

`common.sh` will hold the pieces both tools need: die-with-stderr, reading gzip and plain files, and any shared field splitters. Keep it free of subcommand dispatch. Callers source it; they do not execute it.

When you add it:

```bash
# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
```

Match the repo shell style: bash, `set -euo pipefail` in the entrypoint (not necessarily in a sourced file that inherits the caller's flags), 4-space indent.
