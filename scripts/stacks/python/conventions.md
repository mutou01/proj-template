### Python

Starting points. Edit them.

- `ruff check` and `ruff format` are the gate. Configure both in
  `pyproject.toml` under `[tool.ruff]`, so the line length the formatter uses
  and the line length the linter allows cannot disagree.
- Type-annotate public functions. If you add `mypy`, add it to `LINT_CMD` — a
  type checker that `make verify` does not run is a type checker nobody runs.
- Never `except:` and never `except Exception: pass`. Catch the exception you
  mean, and let the rest fail loudly.
- A failed read raises. It does not return `None`, `[]` or `""` as if the value
  were empty — "could not read" and "read, and it was empty" are different
  facts, and code that conflates them fails open.
- Use `pathlib.Path` rather than string concatenation for paths.
- Tests name the behaviour they check (`test_expired_token_is_rejected`), one
  behaviour per test. A test file name is a sentence about one scenario.
- Tests that must not touch the real machine set `HOME` (and `XDG_CONFIG_HOME`)
  to a `tmp_path`, rather than reading the developer's own config.
- Pin the test runner's imports with an isolated virtualenv; never install into
  the system interpreter.
