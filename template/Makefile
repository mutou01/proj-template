# Makefile — one canonical gate.
#
# One command to run, one exit code to read. When a project has `make test`,
# `npm test` and `pytest` all meaning slightly different things, an agent will
# eventually run the one that passes. So: everything a change must pass is
# behind `verify`, and nothing else counts as evidence.
#
# Needs a POSIX shell (`sh`) for the recipes. On Windows, run make from Git
# Bash — the recipes below use `&&`, `$$(...)` and quoting that cmd.exe does
# not understand.

# --- Folder guard ------------------------------------------------------------
# The recipes name paths relative to the working folder, and `clean` removes
# them, so running from somewhere else (`make -f path/to/Makefile`) would act
# on the wrong tree. `make -C path/to/project` works.
#
# The guard is a file that only exists in a real project of this kind, which is
# also why a freshly created project has to be given one before `make verify`
# will run: that is the guard doing its job, not a bug.
ifeq ($(wildcard {{GUARD_FILE}}),)
  $(error no {{GUARD_FILE}} in $(CURDIR) - run make in the project's folder \
	(make -C path/to/{{PROJECT_SLUG}}). If this IS the project folder, it has \
	no {{GUARD_FILE}} yet: create one, or change this guard)
endif

# `RUN` is what `make test-one` filters on:
#   make test-one RUN='name of the test'
RUN =

# === STACK ===
# Every gate below delegates to these commands, so changing language, formatter
# or test runner means editing this block and nothing else. scripts/init wrote
# the ones for the stack this project was created with; they are yours now.
# === END STACK ===

.PHONY: help setup build test test-one lint fmt fmt-check verify clean

help: ## List the targets.
	@echo "make verify     the gate: fmt-check, lint and the whole test suite"
	@echo "make test-one   one test: make test-one RUN='name of the test'"
	@echo "make setup      install what build, lint and test need"

setup: ## Install what build, lint and test need.
	$(SETUP_CMD)

build: ## Build the project.
	$(BUILD_CMD)

test: ## Run the whole test suite.
	$(TEST_CMD)

test-one: ## Run one test: make test-one RUN='name of the test'
	$(TEST_ONE_CMD)

lint: ## Static analysis.
	$(LINT_CMD)

fmt: ## Format in place.
	$(FMT_CMD)

fmt-check: ## Fail if anything is not formatted.
	$(FMT_CHECK_CMD)

verify: fmt-check lint test ## The gate: everything a change must pass.
	@echo "verify: ok"

clean: ## Remove build output.
	$(CLEAN_CMD)
