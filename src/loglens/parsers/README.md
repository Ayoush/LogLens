# parsers

One module per log source. Each module implements the `LogParser` protocol and yields `LogRecord` values.

| Future module | Source |
|---|---|
| `base.py` | The `Protocol`: `name`, `can_parse`, `parse` |
| `nginx.py` | Combined-style access logs, including the `rt=` request time field |
| `syslog.py` | Auth and syslog lines. Inject the year, and handle the December-to-January rollover |
| `jsonlog.py` | `journalctl -o json` and other JSON line logs |

`can_parse` looks at a sample and returns whether this parser should claim the stream. `parse` is a generator. It skips or records a malformed line without aborting the file, and the tests cover that.

Do not import sibling parsers from each other. The registry, when it arrives, is the only place that knows the full list. That is what makes a fourth parser a new module rather than an edit to the old ones.
