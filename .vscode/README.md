# Editor settings

Shared Cursor and VS Code settings so format-on-save matches the repo.

| File | Role |
|---|---|
| `settings.json` | LF endings, Ruff as the Python formatter, 4-space shell, 100-column ruler. |
| `extensions.json` | Recommends EditorConfig, Ruff, and ShellCheck. |

Personal workspace files are gitignored. EditorConfig in the repository root is the contract for editors that are not VS Code. The pre-commit hooks are the contract that actually rejects a bad diff.
