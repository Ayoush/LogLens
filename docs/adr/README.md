# Architecture decision records

Short, numbered decisions. One file per decision. Later tasks add the files; this README is the format.

```text
docs/adr/0000-trunk-based.md
docs/adr/0001-composition-over-inheritance.md
```

Use the next free number. Do not renumber a merged ADR. Supersede it with a new one that links back.

Each record:

```text
# NNNN. Title

## Status

Proposed, accepted, or superseded by NNNN.

## Context

What forced the decision.

## Decision

What we will do.

## Consequences

What becomes easier, and what we are giving up.
```

`0000` records epic branches (`epic1`, `epic2`) plus short-lived `task/<number>-short-slug` branches. `0001` records composition and a `LogParser` protocol instead of a parser class hierarchy. Those two are already the project defaults; the ADR files exist so the reasoning stays next to the code.
