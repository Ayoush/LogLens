# raw_logs

Drop generated practice logs here. This directory is gitignored except for this README.

Expected local files, none of which should be committed:

| File | Produced by |
|---|---|
| `access.log` | Nginx, with the `timed` log format from the root README |
| `app.json` | A JSON application log used by INT-2 |
| `journal.json` | `journalctl -o json` |

Generate the traffic yourself against localhost. Do not copy a customer or production dump into the repository, including into `tests/fixtures/`, until it has been sanitized.
