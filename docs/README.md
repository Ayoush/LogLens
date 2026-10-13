# docs

Design and learning notes for Epic 0. The folder is the contract; the documents land with the task that writes them.

| Future file | What it has to contain |
|---|---|
| `design.md` | Clarifying questions, FR/NFR, estimates with formulas, SLO, trade-offs, non-goals |
| `bandit-notes.md` | OverTheWire Bandit notes through the level the epic requires |
| `fs-lab.md` | Filesystem lab write-up |
| `one-liners.md` | Unix one-liners the shell toolkit grew out of |
| `permissions.md` | Permission-auditor notes and the lab layout |
| `adr/` | Architecture decision records |

Write these before the Python implementation hardens. The design doc is a gate, not a souvenir: parser and extractor work should be able to point at a decision in `adr/` or a requirement in `design.md`.
