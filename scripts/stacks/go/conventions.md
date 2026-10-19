### Go

Starting points, taken from a Go project that runs this way. Edit them.

- Write `any`, not `interface{}`.
- A comment says what the code is for, in a sentence or two. Name functions
  instead of giving line numbers, which go stale.
- Wrap errors with what was being attempted — `fmt.Errorf("reading config: %w",
  err)` — and branch on `errors.Is` / `errors.As`, never on the message text.
  A caller that matches a string breaks the next time the message is improved.
- Read environment variables that name a folder through a helper that rejects a
  relative path, so a typo cannot quietly resolve to the working directory.
- `go vet ./...` is the linter. Add a stricter one if you want, but add it to
  `LINT_CMD` — a linter that `make verify` does not run is a linter nobody runs.
- Table tests name each case for what it is (`"expired token is rejected"`),
  not for its position.
- A test that must not touch the real machine sets `t.Setenv("HOME", t.TempDir())`
  (and the equivalent on Windows) rather than relying on the developer's setup.
- A module with no packages yet fails `go vet` and `go test` with "no packages
  to vet". That is the gate declining to report success on an empty tree, not a
  misconfiguration — it goes green with your first package.
