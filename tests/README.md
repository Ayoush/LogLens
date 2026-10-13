# tests

Pytest, configured in `pyproject.toml`. The CI `python` job runs pytest once files named `tests/test_*.py` exist. Until then the job typechecks the package and skips collection.

| Future module | Covers |
|---|---|
| `test_parsers.py` | One golden case per parser, plus malformed lines |
| `test_filters.py` | Each filter on its own |
| `test_windowing.py` | Boundaries, including a record that lands exactly on a window edge |
| `test_extractor.py` | Fake client: valid JSON, fenced JSON, prose around JSON, invalid-then-repaired, permanently invalid |

Rules:

- No test opens a network connection. The extractor tests inject a fake client.
- Fixtures under `fixtures/` are sanitized and safe to commit.
- Shell scripts can grow their own `tests/` later; start with a golden output next to the script's task if a Python test would be a worse fit.
- Aim for the epic coverage bar (at least 85% of the core package) once the pipeline exists, not by padding this skeleton.
