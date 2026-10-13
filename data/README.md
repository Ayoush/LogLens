# data

Local inputs that are too sensitive or too large to commit.

`raw_logs/` is where you point Nginx, SSH, and journal exports while you are developing. Those files stay on your machine. The gitignore keeps everything in `raw_logs/` except this tree's README.

When a command needs a fixture that other people can run, copy a sanitized slice into `tests/fixtures/` and commit that. Strip real IPs, usernames, hostnames, and tokens first.

The starter tasks read paths like:

```text
data/raw_logs/access.log
data/raw_logs/app.json
```

Those paths are local. They are not part of the git history.
