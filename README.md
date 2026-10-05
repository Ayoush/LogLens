# LogLens

> **Terminal-first log intelligence for engineers and FDEs.**
>
> Start with Unix pipelines. Graduate to a typed Python CLI. Finish with validated, structured incident extraction from an LLM.

## What is LogLens?

LogLens is a command-line tool for answering the questions you would ask when debugging a customer's Linux server from a terminal:

- Which IPs are hammering the server?
- When did the 5xx errors begin?
- Which endpoints are failing or becoming slow?
- Is someone brute-forcing SSH?
- Did a service restart around the same time as the incident?
- Can the log evidence be turned into a structured incident report?

The project is deliberately built in layers:

```text
Raw server logs
     │
     ├── Shell layer ────────────────┐
     │   grep / awk / sed / sort / jq│
     │                               │
     │       Fast terminal answers   │
     │                               │
     └── Python layer ───────────────┤
         parse → filter → window     │
                  │                  │
                  ↓                  │
             LLM extraction         │
                  │                  │
                  ↓                  │
           Pydantic validation       │
                  │                  │
                  ↓                  │
          Structured incidents       │
                                     │
              ───────────────────────┘
```

The central engineering idea is simple:

> **The machine should do deterministic log processing first. The LLM should be the optional final reasoning stage, not the thing doing all the parsing.**

---

## Project status

**Epic:** 0 — Terminal-First Foundations
**Target duration:** 2 weeks, roughly 25–30 focused hours
**Primary environment:** local Ubuntu machine
**Primary interface:** terminal
**Final milestone:** `v1.0.0`

This README describes the complete Epic 0 scope. The project is intentionally small enough to finish, measure, release, and demo before moving to later infrastructure work.

The repository skeleton is in place: folder contracts, shared formatting, and the contribution checks below. Product code lands with the task that owns it.

---

## How contributions work here

The rules for branches, pull requests, commit messages, formatting, and hooks are in [RULES.md](RULES.md). Install the hooks in that file once per clone. After that, `git commit` runs the checks.

A wrong branch name or a missing task link does not produce a loud error from the tracker. The link simply never happens. CI rejects that pull request so the mistake is visible before merge.

### Get these wrong and the automation silently stops working

1. **Put `Closes INT-<number>` in the pull request description.** This is how the pull request is linked to the task. Without that exact phrase, the pull request is not connected to anything.
2. **Name the branch `task/<number>-short-slug`.** Example: `task/3-kanban-board-ui-layout`. This is the backup link, and it is a checked rule.
3. **Use the task number printed on the task card.** That number looks like `INT-<number>`. A wrong number links the work to someone else's task, and merging marks that task complete.
4. **Open one pull request per task.** If a pull request covers two tasks, only one gets linked. The other is never tracked.

### Also worth knowing

- Link the GitHub account before joining. Pull requests can only be credited to a linked account.
- Do not rename the branch after opening the pull request. The link is resolved when the pull request is opened.
- When the pull request is merged, the task moves to Done automatically.
- The bot posts a review on every pull request. It checks that task's acceptance criteria one by one and suggests what to read. It never blocks the merge. A failing CI check does block the merge. Those are different signals.

---

## Why build this?

LogLens is not just a log-parser project. It is training a set of engineering habits that the later roadmap depends on:

1. **Terminal-first debugging** — work comfortably on a machine where a GUI is not available.
2. **Clarify before coding** — define requirements, non-goals, estimates, SLOs, and trade-offs first.
3. **Composition over inheritance** — keep pipeline components small and replaceable.
4. **Typed boundaries** — normalize different log formats into one internal representation.
5. **Streaming instead of loading everything into memory** — a large log should not require a giant in-memory list.
6. **LLM output is untrusted** — validate model output against a schema and repair invalid responses.
7. **Measure the result** — benchmark parsing, measure token usage, evaluate extraction quality, and compare estimates against reality.
8. **Ship the project** — CI, release automation, documentation, a tagged release, and a short demo are part of the definition of done.

---

## What you will build

By the end of the epic, the repository should contain:

| Artifact | Purpose |
|---|---|
| `dotfiles` | Reusable terminal/Neovim/tmux/Git setup |
| `bootstrap.sh` | Reproduce the workstation on a clean user account |
| `shell/loglens.sh` | Fast Unix-pipeline log analysis |
| `shell/permaudit.sh` | Permission and security audit |
| `loglens` | Typed Python CLI |
| `docs/design.md` | Requirements, estimates, SLO, trade-offs, cost model |
| `docs/bandit-notes.md` | OverTheWire Bandit notes |
| `eval/report.md` | Extraction and cost evaluation |
| `v1.0.0` | Tagged, installable release |

---

# 1. The mental model

If the project feels too abstract, think about one ugly log file first.

Suppose `access.log` contains:

```text
10.0.0.1 - - [29/Sep/2026:10:00:01 +0530] "GET /" 200 123 "-" "curl"
10.0.0.2 - - [29/Sep/2026:10:00:02 +0530] "GET /login" 200 421 "-" "Mozilla/5.0"
10.0.0.3 - - [29/Sep/2026:10:00:03 +0530] "GET /api" 500 912 "-" "curl"
10.0.0.3 - - [29/Sep/2026:10:00:04 +0530] "GET /api" 500 901 "-" "curl"
```

A human may ask:

> How many requests were successful?

> How many requests failed?

> Which IP is making the most requests?

> Did the 500 errors happen together?

LogLens turns those questions into repeatable commands.

The earliest work items are intentionally tiny. For example, the first three starter tasks are:

```text
INT-1  Count Nginx HTTP status codes
INT-2  Extract ERROR entries from JSON logs using jq
INT-3  Find IPs that cross a request-count threshold
```

They are not the whole application. They are the first building blocks for the larger shell toolkit.

---

# 2. Architecture

```mermaid
flowchart LR
    subgraph Sources
        A[nginx access.log]
        B[/var/log/auth.log]
        C[journalctl -o json]
    end

    subgraph Shell[Shell Layer]
        S1[loglens.sh]
        S2[permaudit.sh]
    end

    subgraph Python[Python Layer]
        R[Reader]
        P[Parser Registry]
        P1[NginxParser]
        P2[SyslogParser]
        P3[JSONLogParser]
        F[Filters]
        W[Windowing]
        X[IncidentExtractor]
        L[LLM SDK]
        V[Pydantic Validation]
        RP[Repair Loop]
        K[Sinks]
    end

    A --> S1
    B --> S1
    C --> S1

    A --> R
    B --> R
    C --> R

    R --> P
    P --> P1
    P --> P2
    P --> P3

    P1 --> F
    P2 --> F
    P3 --> F

    F --> K
    F --> W
    W --> X
    X --> L
    L --> V
    V -->|valid| K
    V -->|invalid| RP
    RP --> L
```

## Core pipeline

The Python pipeline is designed around composition:

```text
Reader
  ↓
Parser
  ↓
Filters
  ↓
Windowing
  ↓
IncidentExtractor
  ↓
LLM
  ↓
Pydantic validation
  ↓
Repair / retry when invalid
  ↓
Sink
```

Each component should have one clear responsibility.

### Design principles

**1. Composition over inheritance**

A parser is a component in the pipeline. Avoid a deep class hierarchy such as:

```text
BaseParser → RegexParser → NginxParser
```

Prefer small components connected by interfaces.

**2. One internal log representation**

All parsers produce a common `LogRecord`.

That means filters, windowing, and sinks do not need to know whether an event came from Nginx, syslog, or journald.

**3. The LLM is optional**

Everything before incident extraction should work without an API key. That makes the deterministic core testable and keeps the LLM at the end of the pipeline.

**4. Streaming**

Files should be processed with iterators/generators so a large log does not become a giant Python list in memory.

---

# 3. Repository structure

Folders below exist now. Each one has a README that says what belongs there and which task adds the implementation files. The Python modules, shell commands, and design docs are the target layout; they arrive with the task that owns them.

```text
loglens/
├── .editorconfig
├── .env.example
├── .gitignore
├── .pre-commit-config.yaml
├── .python-version
├── pyproject.toml
├── README.md
├── RULES.md
│
├── .github/
│   ├── pull_request_template.md
│   └── workflows/
│       ├── ci.yml
│       └── contribution-rules.yml
│
├── .vscode/
│   ├── extensions.json
│   └── settings.json
│
├── data/
│   └── raw_logs/                 gitignored except README
│
├── docs/
│   └── adr/
│
├── eval/
│   └── windows/                  gitignored except README
│
├── scripts/                      INT-1, INT-2, INT-3
├── shell/
│   └── lib/
│
├── src/
│   └── loglens/
│       ├── parsers/
│       └── extract/
│
├── tests/
│   └── fixtures/                 sanitized logs safe to commit
│
└── tools/
    └── hooks/
        └── check.sh              branch, commit, and PR rules
```

Target files, added by later tasks:

```text
shell/loglens.sh
shell/permaudit.sh
shell/lib/common.sh
src/loglens/cli.py
src/loglens/models.py
src/loglens/readers.py
src/loglens/filters.py
src/loglens/windowing.py
src/loglens/sinks.py
src/loglens/config.py
src/loglens/parsers/{base,nginx,syslog,jsonlog}.py
src/loglens/extract/{prompts,client,extractor}.py
tests/test_{parsers,filters,windowing,extractor}.py
eval/run_eval.py
eval/report.md
docs/{design,bandit-notes,fs-lab,one-liners,permissions}.md
docs/adr/0000-trunk-based.md
docs/adr/0001-composition-over-inheritance.md
uv.lock                          created by `uv lock`, then committed
```

---

# 4. Log sources

Epic 0 focuses on three source categories:

### Nginx access logs

Used for:

- status counts
- top IPs
- top paths
- 5xx bursts
- slow endpoints
- user-agent analysis

### SSH / syslog logs

Used for:

- failed passwords
- invalid users
- brute-force patterns
- login-related investigation

### Journald JSON

Exported with `journalctl -o json` and used for:

- errors
- service restarts
- system events
- machine-readable log fields

For local practice, generate the traffic yourself. The project does not require a real external attack or production server.

---

# 5. Getting started

## Prerequisites

The original project scope assumes a local Ubuntu environment and a terminal-first workflow.

You need:

- Ubuntu 24.04 LTS or similar
- `tmux`
- Neovim
- Git
- `jq`
- `yq`
- `ripgrep`
- `fd`
- `fzf`
- `bat`
- `eza`
- `zoxide`
- `shellcheck`
- Nginx
- an SSH server bound to localhost
- Python tooling through `uv`
- an LLM API key for the final extraction stage

Keep the LLM key out of Git and set a hard provider spend limit before using the paid stage.

## Terminal-first setup

The environment is intentionally part of the project.

Use:

```bash
# install SSH server
sudo apt install openssh-server

# verify local SSH
ssh localhost

# create an SSH key
ssh-keygen -t ed25519
```

The SSH server should listen only on `127.0.0.1` for this epic.

Create an alias in `~/.ssh/config`:

```text
Host ll
    HostName 127.0.0.1
```

Then:

```bash
ssh ll
```

The project also uses `tmux` so that your terminal session remains recoverable.

---

# 6. Generate realistic sample data

The project needs realistic logs before the parsing work starts.

## Nginx

Install Nginx:

```bash
sudo apt install nginx
```

Use a custom log format that includes request time:

```nginx
log_format timed '$remote_addr - $remote_user [$time_local] "$request" '
                 '$status $body_bytes_sent "$http_referer" "$http_user_agent" '
                 'rt=$request_time';

access_log /var/log/nginx/access.log timed;
```

Generate local traffic that contains:

- normal requests
- 404s
- 5xx bursts
- slow requests

Keep a sanitized copy in the repository as a test fixture.

## SSH failures

For local practice, generate failed authentication events against `localhost` while the SSH server remains localhost-only. Restore password authentication settings afterwards.

If `/var/log/auth.log` is unavailable, use the SSH service events from `journalctl` instead.

## Journald JSON

Export a fixture with:

```bash
journalctl -o json --since "2 days ago" > journal.json
```

Never commit real IPs, usernames, secrets, or other sensitive production data.

---

# 7. Starter tasks

These are the first tasks to make the project concrete.

## INT-1 — Nginx status code aggregator

### Goal

Create:

```text
scripts/nginx_status_count.sh
```

Input:

```text
data/raw_logs/access.log
```

Command:

```bash
scripts/nginx_status_count.sh data/raw_logs/access.log
```

Expected behavior:

```text
200 1250
404 182
500 73
502 21
```

Acceptance criteria:

- the script exists
- the script is executable
- it accepts the log path
- status codes are counted correctly
- counts are sorted by descending frequency
- a missing file returns exit code `1`
- the error is written to stderr

### What this teaches

```text
awk → extract a field
sort → order the values
uniq -c → count repetitions
sort -rn → highest count first
```

---

## INT-2 — JSON error extractor

### Goal

Create:

```text
scripts/json_error_extractor.sh
```

Input:

```text
data/raw_logs/app.json
```

Filter:

```text
.level == "ERROR"
```

Output:

```json
[
  {
    "timestamp": "...",
    "message": "...",
    "trace_id": "..."
  }
]
```

Acceptance criteria:

- the script exists and is executable
- `jq` performs the filtering
- only error entries are returned
- the output is valid JSON
- each object contains timestamp, message, and trace ID

### What this teaches

```text
JSON input
   ↓
jq select()
   ↓
field projection
   ↓
valid JSON output
```

---

## INT-3 — IP rate analyzer

### Goal

Create:

```text
scripts/ip_rate_analyzer.sh
```

Command:

```bash
scripts/ip_rate_analyzer.sh data/raw_logs/access.log 100
```

Expected behavior:

```text
1832 10.0.0.1
945  10.0.0.2
431  10.0.0.7
```

Only IPs with more than the specified number of requests are shown.

Acceptance criteria:

- accepts a log path and threshold
- counts requests per IP
- filters by threshold
- prints `COUNT IP`
- sorts numerically from highest to lowest

### What this teaches

```text
extract field
    ↓
sort
    ↓
uniq -c
    ↓
awk threshold
    ↓
sort -rn
```

---

# 8. Shell toolkit

After the starter tasks, these small scripts become one reusable shell tool.

The target command set is:

```text
loglens.sh top-ips
loglens.sh status
loglens.sh 5xx-per-min
loglens.sh top-paths
loglens.sh slowest
loglens.sh user-agents
loglens.sh ssh-fails
loglens.sh ssh-users
loglens.sh journal-errors
loglens.sh restarts
loglens.sh big-files
loglens.sh window
```

Examples:

```bash
./shell/loglens.sh top-ips /var/log/nginx/access.log
./shell/loglens.sh status /var/log/nginx/access.log
./shell/loglens.sh 5xx-per-min /var/log/nginx/access.log
./shell/loglens.sh ssh-fails /var/log/auth.log
./shell/loglens.sh journal-errors journal.json
```

The toolkit should support rotated logs, including compressed files, where appropriate.

A useful pattern is:

```bash
zcat -f access.log*
```

The shell layer is deliberately boring. That is a feature: the goal is to become extremely fast with Unix text-processing primitives.

---

# 9. Permission auditor

The second shell tool is:

```text
shell/permaudit.sh
```

It checks for things such as:

- world-writable files
- world-writable directories without the sticky bit
- setuid/setgid files
- extended ACLs
- login-shell users
- sudo membership
- sensitive file modes
- current `umask`

The project includes a safe lab folder where deliberately bad permissions can be planted and detected.

**Important:** do permission experiments inside the lab folder, not arbitrary system locations.

---

# 10. Design before Python

Before implementing the typed Python system, write:

```text
docs/design.md
```

The design document must include:

### Clarifying questions

Examples:

- Which log sources are required?
- How much data arrives per day?
- Can logs leave the machine?
- Do logs contain PII?
- Is the workflow real-time or after-the-fact?
- Who consumes the output?
- What is the budget ceiling?
- What is the retention requirement?

### Functional requirements

Examples:

- parse Nginx, syslog, and journal JSON
- filter by time, host, level, and regex
- group records into time windows
- extract incidents
- export structured output

### Non-functional requirements

Examples:

- bounded processing time
- bounded memory
- controlled LLM cost
- privacy safeguards
- offline operation before extraction

### Estimation

Record formulas and measured inputs for:

- lines/day
- average bytes/line
- storage/day
- storage/month
- peak lines/sec
- windows/day
- tokens/window
- tokens/day
- extraction cost/day

### SLO

Define an explicit target for extraction latency and schema validity.

### Trade-offs

Document decisions such as:

- regex parsers vs generic parsing libraries
- raw log lines vs pre-aggregated summaries
- synchronous vs asynchronous model calls
- one provider vs multiple providers

### Non-goals

State what will deliberately not be built in Epic 0.

---

# 11. Python CLI

The Python system is where LogLens becomes a reusable software product rather than a collection of shell commands.

## Internal model

Every parser creates a `LogRecord` with a common shape:

```python
class LogRecord(BaseModel, frozen=True):
    ts: datetime
    source: str
    host: str | None = None
    level: Level = Level.INFO
    message: str
    fields: dict[str, str | int | float] = Field(default_factory=dict)
    raw: str
```

## Parser interface

Use a `Protocol` rather than forcing every parser into an inheritance hierarchy.

Conceptually:

```python
class LogParser(Protocol):
    name: str

    def can_parse(self, sample: str) -> bool: ...

    def parse(self, lines: Iterable[str]) -> Iterator[LogRecord]: ...
```

Initial parsers:

```text
NginxParser
SyslogParser
JSONLogParser
```

The extensibility test is important:

> Can a fourth parser be added without editing the existing parser implementations or pipeline code?

---

# 12. Filters and windowing

After parsing, the records should be filterable without caring about their original source.

Examples:

```text
since(timestamp)
until(timestamp)
min_level(level)
matches(regex)
```

Then group the records into fixed-size windows, for example:

```text
10:00 → 10:05
10:05 → 10:10
10:10 → 10:15
```

Each window should contain useful aggregate information such as:

- counts by severity
- counts by status
- counts by source
- top IPs
- top paths
- representative log lines

This is an important architecture decision because **the model should not receive an entire raw log when a compact summary can preserve the useful signal.**

---

# 13. CLI design

The target command-line interface is:

```text
loglens parse FILE... [--format auto|nginx|syslog|journal]
                 [--since] [--until] [--level] [--grep]
                 [--out table|json|jsonl]

loglens stats FILE... [--by status|ip|path|level|unit] [--top 10]

loglens windows FILE... [--minutes 5]

loglens extract FILE... [--minutes 5]
                   [--concurrency 4]
                   [--model ...]
                   [--dry-run]
```

The `--dry-run` extraction path should estimate tokens and projected cost without making a paid model call.

---

# 14. LLM incident extraction

This is the final and most AI-specific layer.

## Input

A compact time window containing:

- window start/end
- aggregates
- a limited number of representative log lines

## Output

The model must return a structure equivalent to:

```python
class Evidence(BaseModel):
    ts: datetime
    line: str = Field(max_length=500)


class Incident(BaseModel):
    title: str = Field(max_length=120)
    severity: Literal["low", "medium", "high", "critical"]
    category: Literal[
        "availability",
        "performance",
        "security",
        "config",
        "resource",
        "other",
    ]
    start: datetime
    end: datetime
    affected: list[str]
    probable_cause: str = Field(max_length=400)
    evidence: list[Evidence] = Field(min_length=1, max_length=5)
    confidence: float = Field(ge=0, le=1)


class ExtractionResult(BaseModel):
    window_start: datetime
    window_end: datetime
    incidents: list[Incident]
```

## Why validation matters

LLMs can return:

- prose around JSON
- fenced JSON
- invalid enum values
- wrong field types
- truncated output
- missing required fields

The extraction loop should therefore be:

```text
Prompt model
     ↓
Receive text
     ↓
Parse JSON
     ↓
Pydantic validation
     │
     ├── valid ─────────→ return result
     │
     └── invalid
              ↓
         build repair prompt
              ↓
         retry within bound
              ↓
         validate again
```

The extractor should also use bounded concurrency and backoff rather than firing unlimited requests at the provider.

---

# 15. Prompt safety

Logs are attacker-controlled data.

A user-agent or SSH username could contain text that looks like instructions.

The prompt should therefore explicitly distinguish **data** from **instructions**.

Conceptually:

```text
<logs>
... attacker-controlled log data ...
</logs>
```

and the system instruction should say that the contents are data, not instructions.

The evaluation suite includes a malicious fixture to test this behavior.

---

# 16. Cost control

The LLM is not the first parser.

The intended cost-control strategy is:

```text
Raw logs
   ↓
Deterministic parsing
   ↓
Aggregation
   ↓
5-minute windows
   ↓
Small sample of evidence lines
   ↓
LLM
```

This reduces both token usage and unnecessary model calls.

The CLI should support:

```bash
loglens extract ... --dry-run
```

before any paid execution.

Actual token usage should be recorded and compared against the original estimate in the evaluation report.

---

# 17. Testing strategy

The project should be testable without a real LLM connection.

## Parser tests

At least one golden test per parser:

```text
NginxParser
SyslogParser
JSONLogParser
```

Also include malformed-line tests.

## Filter tests

Test each filter independently.

## Windowing tests

Test boundary conditions, especially records exactly on a window edge.

## CLI smoke tests

Use Typer's CLI runner.

## LLM tests

Use a fake client that returns:

1. valid JSON
2. JSON inside code fences
3. prose + JSON
4. invalid enum followed by valid repaired output
5. permanently invalid output

No test should need the network.

---

# 18. Benchmarking

Create a generated dataset containing approximately one million Nginx lines.

Measure:

- elapsed time
- peak memory
- behavior under a one-CPU / 1 GB memory constraint

The important requirement is constant-memory streaming rather than simply achieving a fast laptop benchmark.

---

# 19. Evaluation

The final evaluation should contain measurable evidence, not just "it worked on my machine."

## Schema validity

Run extraction on 200 windows:

```text
Before repair
After repair
Mean attempts/window
```

Target: at least 95% schema-valid output after repair.

## Correctness

Hand-label 30 windows and report:

- incident precision
- incident recall
- category agreement

## Cost

Compare:

```text
estimated daily cost
vs
actual measured daily cost
```

Explain any meaningful gap.

## Security / injection

Document what happened with the malicious log line and which defenses worked or failed.

---

# 20. CI and Git workflow

Trunk-based development on `main`, with one long-lived branch per epic (`epic1`, `epic2`) and short-lived `task/<number>-short-slug` branches. One pull request per task, into the epic branch. The full contract for everyone is in [RULES.md](RULES.md).

These files implement it:

```text
.pre-commit-config.yaml
tools/hooks/check.sh
.github/pull_request_template.md
.github/workflows/ci.yml
.github/workflows/contribution-rules.yml
.editorconfig
pyproject.toml
```

| Check | Enforced by |
|---|---|
| Branch `epic<number>`, `mentor/<slug>`, or `task/<number>-short-slug` | `check.sh branch` on commit and push, and `contribution-rules` on the pull request |
| Task pull requests target an epic branch | `contribution-rules`, using the pull request base |
| Exactly one `Closes INT-<number>`, matching the task branch | `contribution-rules` |
| Conventional Commits | commit-msg hook, and the `commits` job for every subject on the pull request |
| Ruff, shfmt, ShellCheck, whitespace, secrets | pre-commit locally and the `formatting` job |
| `mypy --strict` and pytest | `python` job. Pytest runs once `tests/test_*.py` exists |

Release automation is still a later exit criterion for `v1.0.0`. It is not part of this skeleton.

Accepted subjects:

```text
feat: add nginx status analyzer
fix: handle missing log file
chore: update CI workflow
```

Rejected:

```text
updated stuff
```

Keep each pull request small enough to review in one sitting.

---

# 21. DORA metrics

The project includes a small script to calculate delivery metrics from Git history.

At minimum, capture:

- deployment frequency / tag frequency
- lead time from first commit to merge

The point is not to optimize the numbers artificially. The point is to understand the engineering system you created.

---

# 22. Two-week execution plan

| Day | Focus | Output |
|---|---|---|
| 1 | Terminal, tmux, local SSH | `ssh ll` works |
| 2 | Dotfiles, bootstrap, CI, pre-commit | first PR merged |
| 3 | Nginx logs, traffic generation, fixtures, filesystem lab | sanitized fixtures |
| 4 | First half of shell toolkit | commands tested |
| 5 | Remaining shell commands, gzip support, report | ShellCheck clean |
| 6 | Permission auditor + lab | `permaudit.sh` |
| 7 | Design sheet + ADR + class diagram | `docs/design.md` |
| 8 | Models, Protocol, Nginx parser | parser tests green |
| 9 | Syslog + journal parsers, filters, windowing | core pipeline works |
| 10 | Sinks, CLI, streaming, benchmark | parse/stats/windows complete |
| 11 | Incident schema, fake LLM, repair loop | extractor tests green |
| 12 | Real client, concurrency, backoff, redaction, dry-run | real extraction works |
| 13 | Evaluation, labels, cost check, README | `eval/report.md` |
| 14 | Release, clean install, write-up, retro | `v1.0.0` |

Every night:

```text
30 minutes of OverTheWire Bandit
```

---

# 23. Definition of Done

## Linux and shell

- [ ] A new user can reproduce the environment with `bootstrap.sh`.
- [ ] Bandit level 20+ is completed with notes.
- [ ] `loglens.sh` works on fixtures and compressed logs.
- [ ] Ten random log questions can be answered in under two minutes each.
- [ ] `permaudit.sh` catches the planted lab problems.
- [ ] The filesystem lab is completed and explained.

## Engineering practice

- [ ] Trunk-based workflow is enforced.
- [ ] Epic branches use `epic<number>`, and task branches use `task/<number>-short-slug`.
- [ ] Every pull request description contains one `Closes INT-<number>` for that same number.
- [ ] Conventional commits are enforced.
- [ ] CI is green.
- [ ] Release automation produces `v1.0.0`.
- [ ] DORA numbers are recorded.

## Design

- [ ] `docs/design.md` contains clarifying questions.
- [ ] FR/NFR are documented.
- [ ] Estimates include formulas and measured inputs.
- [ ] SLO is defined.
- [ ] Trade-offs and non-goals are explicit.
- [ ] Actual and estimated LLM cost are compared.

## Python

- [ ] `mypy --strict` passes.
- [ ] Core coverage is at least 85%.
- [ ] Three parsers share one Protocol.
- [ ] A fourth parser can be added with minimal existing-code changes.
- [ ] One million log lines can be parsed with constant memory within the chosen NFR.

## AI

- [ ] Schema-validity evaluation is run on 200 windows.
- [ ] Repair improves the validity rate to the project target.
- [ ] Precision/recall is measured on 30 labelled windows.
- [ ] No tests call the real network.
- [ ] `--dry-run` cost estimation works.
- [ ] No secrets are committed.
- [ ] Prompt-injection fixture behavior is documented.

## Presentation

- [ ] README contains architecture and metrics.
- [ ] A short terminal demo/GIF exists.
- [ ] A technical write-up is drafted.
- [ ] The whole system can be demonstrated in roughly five minutes.

---

# 24. What is deliberately NOT being built yet?

Epic 0 does **not** try to become a full observability platform.

Out of scope:

- real-time tailing daemons
- web UI
- database-backed log storage
- multi-machine log shipping
- container deployment
- multi-provider LLM gateway

These are deliberately deferred to later work.

That boundary is important. A strong engineering project is not just a list of features; it also explains what it refuses to build in the current version.

---

# 25. Future extensions

Only after the Definition of Done is complete, possible stretch work includes:

| Extension | Later concept |
|---|---|
| `loglens tail -f` | streaming |
| second LLM provider behind the same interface | provider gateway |
| local Ollama model | local inference |
| Dockerfile | containers |
| signed incident webhook | webhook integrations |
| Postgres-backed storage | database architecture |

Do not let stretch goals replace the core deliverables.

---

# 26. Troubleshooting

| Problem | Likely cause | Direction |
|---|---|---|
| `Permission denied (publickey)` | SSH key or file permissions | check `~/.ssh` and `authorized_keys` permissions |
| `/var/log/auth.log` missing | `rsyslog` is not installed | install it or use `journalctl -u ssh` |
| `uniq -c` counts look wrong | input was not sorted | sort before `uniq` |
| pipeline exits unexpectedly with `pipefail` | upstream gets SIGPIPE from `head` | understand and handle intentionally |
| Nginx timestamp parse fails | format/timezone mismatch | use the documented `%d/%b/%Y:%H:%M:%S %z` format |
| syslog year is wrong | classic syslog omits year | inject year and handle Dec → Jan rollover |
| many LLM results fail validation | malformed output or too-strict schema | tighten prompt, strip fences, review constraints |
| HTTP 429 during extraction | concurrency too high | reduce concurrency and add backoff/jitter |
| disk full but `du` is small | deleted file still open | inspect with `lsof` for deleted descriptors |

---

# 27. Interview stories this project gives you

## Reliable LLM output

> "I do not trust raw model output. I constrain the schema, validate with Pydantic, repair invalid responses, bound retries, and measure the before/after validity rate."

## LLM cost control

> "I aggregate logs before prompting, estimate cost with a dry run, record actual usage, and compare measured cost against the design estimate."

## Debugging a customer's server

> "I can triage an unfamiliar log dump from a terminal using repeatable Unix pipelines before reaching for more infrastructure."

## Protocol vs inheritance

> "The parser boundary uses structural typing so a new parser can plug in without inheriting from our base class."

## Security in AI systems

> "Logs are attacker-controlled input, so I treat them as data, delimit them, validate evidence, and test the behavior against an injection fixture."

## System design

> "Before coding, I wrote clarifying questions, FR/NFR, estimates, SLOs, cost assumptions, trade-offs, and non-goals."

---

# 28. Learning resources

The project guide recommends resources across the major skills being practiced:

### Linux

- Linux Journey
- *The Linux Command Line* — William Shotts
- OverTheWire Bandit
- Julia Evans' Linux zines
- *The AWK Programming Language*
- `jq` documentation

### Git / DevOps

- Pro Git
- DORA
- Conventional Commits
- Trunk Based Development
- pre-commit
- release automation documentation

### Low-level design

- Refactoring.Guru
- *A Philosophy of Software Design* — John Ousterhout
- Python `typing.Protocol` / PEP 544

### Python / AI

- `uv`
- Pydantic v2
- Typer
- Python `asyncio`
- Anthropic API documentation
- OpenAI API documentation

### System design

- Latency numbers / back-of-the-envelope estimation references
- Google SRE material on SLOs
- Your model provider's current pricing documentation

---

# 29. The project in one picture

```text
                         LOG FILES
                            │
             ┌──────────────┴──────────────┐
             │                             │
             ▼                             ▼
       SHELL TOOLKIT                 PYTHON CLI
     grep / awk / jq                parse / filter
             │                      window / sink
             │                             │
             │                             ▼
             │                     5-minute windows
             │                             │
             │                             ▼
             │                       LLM extractor
             │                             │
             │                             ▼
             │                    Pydantic validation
             │                             │
             │                   ┌─────────┴─────────┐
             │                   │                   │
             │                 valid              invalid
             │                   │                   │
             │                   ▼                   ▼
             │                incident          repair/retry
             │                                       │
             └───────────────────────────────────────┘

                     MEASURE → TEST → RELEASE
```

---

# 30. Final goal

LogLens is complete when you can sit at a terminal, receive an unfamiliar server log dump, and demonstrate a clear progression:

```text
raw logs
   ↓
fast Unix triage
   ↓
structured parsing
   ↓
time-windowed analysis
   ↓
incident extraction
   ↓
validated structured output
   ↓
measured quality + measured cost
```

The goal is not to build the biggest log platform.

The goal is to build a **small, complete, measurable system** that demonstrates Linux fluency, practical shell skills, clean Python design, system-design thinking, reliable LLM integration, and the ability to ship.

---

## License

Choose a license before publishing the repository publicly. The project guide does not prescribe a specific license.

---

## Author / Project Notes

Use this section for your own project links, demo video, architecture notes, release history, and learning notes as the project evolves.
