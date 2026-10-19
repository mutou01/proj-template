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
# The guard looks for a file that a real project of this kind has. It is
# advisory, not proof of ownership: another project of the same stack passes it
# too. Its job is to fail loudly before a recipe touches the wrong tree, not to
# authenticate the directory.
ifeq ($(wildcard {{GUARD_FILE}}),)
  $(error no {{GUARD_FILE}} in $(CURDIR) - run make in the project's folder \
	(make -C path/to/{{PROJECT_SLUG}}). If this IS the project folder, it has \
	no {{GUARD_FILE}} yet: create one, or change this guard)
endif

# `RUN` is what `make test-one` filters on:
#   make test-one RUN='name of the test'
RUN =

# Every gate below delegates to the commands between the STACK markers, so
# changing language, formatter or test runner means editing that block and
# nothing else. The commands were written for the stack this project was
# created with, and they are yours now. They describe what a real project must
# be able to run; a project with no code yet will fail them, and that is
# expected.
# === STACK ===
# === END STACK ===

.PHONY: help setup build test test-one lint fmt fmt-check verify clean

help: ## List the targets.
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

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

verify: fmt-check lint build test ## The gate: everything a change must pass.
	@echo "verify: ok"

clean: ## Remove build output.
	$(CLEAN_CMD)
