# windows

Local window payloads for `eval/run_eval.py`. Gitignored except for this README.

A window is the compact object the model sees: start, end, aggregates, and a few representative lines. Those lines can still carry IPs, usernames, and hostnames. Keep them on your machine.

Committed evidence belongs in `eval/report.md` as measurements, not as a dump of the windows themselves.
