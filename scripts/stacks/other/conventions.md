### This project's stack

No stack block was generated, because none of the known ones were chosen.

Write down, here, the things a newcomer would otherwise learn by breaking them:

- the command that formats, and the one that checks formatting without
  rewriting;
- the linter, and which of its rules are deliberately off;
- the test runner, how to run one test, and where test data lives;
- how a test isolates itself from the real machine — a temporary home
  directory, a pinned cache, a scratch database;
- what must never appear in the repository (secrets, generated files, vendored
  dependencies) and what regenerates them instead.

Then fill in the `STACK` block in the `Makefile`, so `make verify` runs them.
Until it does, `make verify` fails on purpose — see the comment in that block.
