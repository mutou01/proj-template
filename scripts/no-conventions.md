### This project's stack

No language conventions were generated, because `--no-conventions` was passed.

Write down, here, the things a newcomer would otherwise learn by breaking them:

- the command that formats, and the one that checks formatting without
  rewriting;
- the linter, and which of its rules are deliberately off;
- the test runner, how to run one test, and where test data lives;
- how a test isolates itself from the real machine — a temporary home
  directory, a pinned cache, a scratch database;
- what must never appear in the repository (secrets, generated files, vendored
  dependencies) and what regenerates them instead.

The gate itself is already wired up: see the `STACK` block in the `Makefile`.
