# eval

Measurement for the extraction stage. "It worked on my machine" is not an evaluation.

| Future file | Role |
|---|---|
| `run_eval.py` | Runs schema-validity, labelled correctness, and cost checks |
| `report.md` | The numbers: validity before and after repair, precision and recall, estimated cost versus measured cost |
| `windows/` | Window payloads fed to the evaluator |

Targets from the epic:

- 200 windows for schema validity, with a goal of at least 95% valid after repair.
- 30 hand-labelled windows for precision, recall, and category agreement.
- A written note on the prompt-injection fixture.

`windows/` is gitignored except for its README. A window can still contain log lines, so treat it like a raw log: sanitize before anything in here is committed, and prefer keeping raw windows local.
