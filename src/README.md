# src

Python package root using the `src` layout. Import the library as `loglens`, never as `src.loglens`.

`pyproject.toml` tells Hatchling to ship `src/loglens`. Editable installs and mypy both use that path (`mypy_path = "src"`).

The only package under here is `loglens/`. Do not add a second top-level package without an ADR.
