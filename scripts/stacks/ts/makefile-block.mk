# `npm` unless the project uses pnpm or yarn. Override with `make NPM=pnpm`.
NPM           ?= npm

# `npm install`, not `npm ci`: a project created a minute ago has no lock file
# for `ci` to read. Switch to `npm ci` in CI once a lock file is committed —
# it is the whole point of committing one.
SETUP_CMD     = $(NPM) install
BUILD_CMD     = $(NPM) run build
TEST_CMD      = $(NPM) test
# `--test-name-pattern` is the runtime runner's flag, and matches the runner
# the conventions recommend. A project using Jest or Vitest replaces this line
# with that runner's name filter.
TEST_ONE_CMD  = node --test --test-name-pattern '$(RUN)'
LINT_CMD      = $(NPM) run lint
FMT_CMD       = $(NPM) run format
FMT_CHECK_CMD = $(NPM) run format:check
CLEAN_CMD     = rm -rf dist build coverage
