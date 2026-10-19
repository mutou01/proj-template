# Nothing is configured yet, so every gate fails on purpose.
#
# A gate that prints a warning and exits 0 is worse than no gate: it makes an
# unrun check look like a passing one, which is the failure mode this whole
# template exists to prevent. Fill these in and the gate starts working.
#
# Replace each line with the real command for this project's stack.
#
# The messages below are deliberately ASCII-only. A Windows console running a
# codepage other than UTF-8 renders an em dash as mojibake, and a build tool
# whose own error message is unreadable is a poor place to start debugging.

SETUP_CMD     = echo "setup: not configured - edit the STACK block in Makefile" >&2; exit 1
BUILD_CMD     = echo "build: not configured - edit the STACK block in Makefile" >&2; exit 1
TEST_CMD      = echo "test: not configured - edit the STACK block in Makefile" >&2; exit 1
TEST_ONE_CMD  = echo "test-one: not configured - edit the STACK block in Makefile" >&2; exit 1
LINT_CMD      = echo "lint: not configured - edit the STACK block in Makefile" >&2; exit 1
FMT_CMD       = echo "fmt: not configured - edit the STACK block in Makefile" >&2; exit 1
FMT_CHECK_CMD = echo "fmt-check: not configured - edit the STACK block in Makefile" >&2; exit 1
CLEAN_CMD     = echo "clean: not configured - edit the STACK block in Makefile" >&2; exit 1
