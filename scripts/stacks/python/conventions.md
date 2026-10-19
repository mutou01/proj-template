### Python

Starting points. Edit them.

- `ruff check` and `ruff format --check` are the gate — the check, not the
  rewrite, because a gate that changes files cannot fail for the right reason.
  Configure both in `pyproject.toml` under `[tool.ruff]`, so the line length
  the formatter uses and the line length the linter allows cannot disagree.
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
- The gate runs inside whatever `PYTHON` resolves to. To work in an isolated
  environment, pass it in — `make verify PYTHON=.venv/bin/python`, or
  `.venv\Scripts\python.exe` on Windows — rather than relying on whichever
  interpreter happens to be first on PATH. CI installs into the runner's
  interpreter, which is disposable.
