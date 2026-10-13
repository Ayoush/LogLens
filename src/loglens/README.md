# loglens

The importable package. Deterministic pipeline first. The LLM is the optional last stage.

| Future module | Responsibility |
|---|---|
| `cli.py` | Typer commands: `parse`, `stats`, `windows`, `extract` |
| `models.py` | `LogRecord` and the incident schema |
| `readers.py` | Streaming readers. A large file must not become one in-memory list |
| `filters.py` | `since`, `until`, `min_level`, `matches` |
| `windowing.py` | Fixed time windows and their aggregates |
| `sinks.py` | `table`, `json`, `jsonl` output |
| `config.py` | Settings, including the dry-run cost path |
| `parsers/` | Nginx, syslog, and journal JSON parsers behind one protocol |
| `extract/` | Prompt, client, validation, and the bounded repair loop |

`__init__.py` currently exports nothing but the version. Add public re-exports only when a caller outside the package needs them.

Design constraints that already apply:

- One internal `LogRecord` for every source.
- A parser is a `Protocol`, not a base class people must inherit.
- A fourth parser must be addable without editing the existing parser modules or the pipeline.
- Everything before `extract` runs with no API key.
- Model output is untrusted until Pydantic accepts it.
