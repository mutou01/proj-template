# `python` on Windows, `python3` on most Unix. Override with `make PYTHON=python3`.
PYTHON        ?= python

SETUP_CMD     = $(PYTHON) -m pip install -e ".[dev]"
BUILD_CMD     = $(PYTHON) -m build
TEST_CMD      = $(PYTHON) -m pytest
TEST_ONE_CMD  = $(PYTHON) -m pytest -k '$(RUN)'
LINT_CMD      = $(PYTHON) -m ruff check .
FMT_CMD       = $(PYTHON) -m ruff format .
# `ruff format --check` exits non-zero on its own when something is unformatted,
# so unlike gofmt there is nothing to inspect.
FMT_CHECK_CMD = $(PYTHON) -m ruff format --check .
CLEAN_CMD     = rm -rf dist build *.egg-info .pytest_cache .ruff_cache .mypy_cache
