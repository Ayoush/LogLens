# fixtures

Small, sanitized logs that tests and shell commands can rely on. This is the directory that *is* committed.

Put a fixture here when:

- another person, and CI, must be able to run the same command
- the file contains no real IP that you care about, no real username, no hostname from a customer, and no secret
- the file is small enough to review in a diff (the pre-commit large-file check rejects anything over 500 KB)

Generate messy originals in `data/raw_logs/`. Copy the slice you need, replace identifying fields with obvious fakes (`10.0.0.1`, `user-a`, `web-1`), and commit the copy.

Name files after the case they serve, for example `nginx_5xx_burst.log` or `journal_restart.json`. One behavior per file makes a failing test point at the case.
