# extract

The only package that talks to a model. Callers pass a compact window, not a raw log file.

| Future module | Responsibility |
|---|---|
| `prompts.py` | Instructions plus a delimited data block. Log text is data, not instructions |
| `client.py` | Provider call, timeout, concurrency, and backoff. Tests use a fake, never the network |
| `extractor.py` | Parse JSON, validate with Pydantic, build a repair prompt, retry inside a fixed bound |

`extract --dry-run` estimates tokens and cost and returns before any paid call. Live calls read the key from the environment (see `.env.example`). A missing key fails the live path and leaves dry-run working.

Schema targets live in the root README: `Evidence`, `Incident`, and `ExtractionResult`. Keep field limits in the models so a long model answer cannot smuggle an unbounded log line into the result.
