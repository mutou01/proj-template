#!/usr/bin/env sh
#
# init.sh — create a project from this template.
#
#   scripts/init.sh <target-dir> --name <name> [--desc "<one line>"]
#                   [--lang go|python|ts|other] [--no-conventions] [--git] [--force]
#
# Copies template/ into <target-dir> and fills in the project's name,
# description and stack. For a known stack it also writes the stack block into
# the Makefile, the code standards and the CI workflow.
#
# The verification commands it writes are a contract, not a working build: they
# are what a real project must be able to run. A fresh project has no code, so
# the gate is expected to fail until there is something to check.
#
# The edits are made with awk rather than `sed -i`, because GNU sed and
# BSD/macOS sed disagree about what `-i` takes and about whether it wants a
# backup suffix. That difference is invisible until someone on the other
# platform runs this, which is the worst time to find out.

set -eu

# --- locate this script and the template it ships with -----------------------
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$here/.." && pwd)
template="$root/template"
stacks="$here/stacks"

die() { printf 'init: %s\n' "$*" >&2; exit 1; }

usage() {
	cat <<'EOF'
Usage: scripts/init.sh <target-dir> [options]

  --name <name>       Project name, as it should read in the docs. Defaults to
                      the target directory's name.
  --desc "<text>"     One line describing the project. Optional.
  --lang <stack>      go | python | ts | other. Defaults to other.
  --no-conventions    Do not write the stack's language conventions into
                      docs/code-standards.md. The gate is still written.
  --git               Run `git init -b main` in the new project. Nothing is
                      staged or committed.
  --force             Write into a target directory that is not empty.
  -h, --help          This text.

Examples:
  scripts/init.sh ../my-service --name my-service --desc "Does the thing" --lang go --git
  scripts/init.sh ./scratch --name scratch --lang python --no-conventions
EOF
}

# --- arguments ---------------------------------------------------------------
target=''
name=''
desc=''
lang='other'
conventions=1
do_git=0
force=0

# Reads the value after an option, so a missing one fails with a sentence
# rather than with `shift: can't shift that many`.
take_value() {
	[ "$1" -ge 2 ] || die "$2 needs a value"
}

while [ $# -gt 0 ]; do
	case "$1" in
	--name)
		take_value $# --name
		name=$2
		shift 2
		;;
	--desc)
		take_value $# --desc
		desc=$2
		shift 2
		;;
	--lang)
		take_value $# --lang
		lang=$2
		shift 2
		;;
	--no-conventions)
		conventions=0
		shift
		;;
	--git)
		do_git=1
		shift
		;;
	--force)
		force=1
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	-*)
		die "unknown option: $1 (try --help)"
		;;
	*)
		[ -z "$target" ] || die "more than one target directory given: '$target' and '$1'"
		target=$1
		shift
		;;
	esac
done

case "$lang" in
go | python | ts | other) ;;
*) die "--lang must be go, python, ts or other (got '$lang')" ;;
esac

[ -n "$target" ] || {
	usage >&2
	die "no target directory given"
}

[ -d "$template" ] || die "no template directory at $template"
[ -d "$stacks/$lang" ] || die "no stack definition at $stacks/$lang"

if [ "$conventions" -eq 1 ]; then
	conventions_src="$stacks/$lang/conventions.md"
else
	conventions_src="$here/no-conventions.md"
fi
[ -f "$conventions_src" ] || die "no conventions file at $conventions_src"

# --- target directory --------------------------------------------------------
mkdir -p -- "$target"
target=$(CDPATH= cd -- "$target" && pwd)

# Refuse a directory that already has something in it. Copying a template over
# someone's work is not something this script can undo, and a half-overwritten
# tree is worse than a refusal.
if [ "$force" -eq 0 ] && [ -n "$(ls -A -- "$target" 2>/dev/null || true)" ]; then
	die "$target is not empty (pass --force to write into it anyway)"
fi

# --- the values that get substituted -----------------------------------------
if [ -z "$name" ]; then
	name=$(basename -- "$target")
fi

slug=$(printf '%s' "$name" |
	tr '[:upper:]' '[:lower:]' |
	tr -c 'a-z0-9' '-' |
	tr -s '-' |
	sed -e 's/^-//' -e 's/-$//')
[ -n "$slug" ] || slug=project

case "$lang" in
go) lang_label='Go' ;;
python) lang_label='Python' ;;
ts) lang_label='TypeScript / Node' ;;
other) lang_label='Other' ;;
esac

# The separator travels with the description, so an omitted --desc leaves no
# dangling dash behind. The em dash is kept out of the awk program below and
# passed in as a value, so the script's encoding never reaches awk's parser.
if [ -n "$desc" ]; then
	desc_suffix=" — $desc"
else
	desc_suffix=''
fi

guard=$(tr -d ' \t\r\n' <"$stacks/$lang/guard")
[ -n "$guard" ] || die "$stacks/$lang/guard is empty"

# --- copy --------------------------------------------------------------------
cp -R -- "$template/." "$target/"

# --- substitute the placeholders ---------------------------------------------
# Only the files the template ships, found by walking the template rather than
# the target. With --force the target may already hold a user's own files, and
# rewriting those — or re-encoding a user's binary because it happened to
# contain the bytes `{{PROJECT_NAME}}` — is not this script's business.
#
# The replacement is a literal substring swap, not `gsub`. In a gsub
# replacement, `&` means "the matched text", so a project called `A & B` would
# come out as `A {{PROJECT_NAME}} B`, with the script exiting 0.
find "$template" -type f -print | while IFS= read -r src; do
	rel=${src#"$template"/}
	file="$target/$rel"
	[ -f "$file" ] || continue
	# Values arrive through the environment, not `awk -v`: `-v` processes
	# backslash escapes, so a description containing `\w` would lose the
	# backslash. ENVIRON hands awk the bytes unchanged.
	INIT_NAME="$name" INIT_SLUG="$slug" INIT_DESC_SUFFIX="$desc_suffix" \
		INIT_LANG="$lang_label" INIT_GUARD="$guard" \
		awk '
		BEGIN {
			name = ENVIRON["INIT_NAME"]
			slug = ENVIRON["INIT_SLUG"]
			desc_suffix = ENVIRON["INIT_DESC_SUFFIX"]
			lang = ENVIRON["INIT_LANG"]
			guard = ENVIRON["INIT_GUARD"]
		}
		function replace_all(text, needle, repl,    out, i) {
			out = ""
			while ((i = index(text, needle)) > 0) {
				out = out substr(text, 1, i - 1) repl
				text = substr(text, i + length(needle))
			}
			return out text
		}
		{
			line = $0
			line = replace_all(line, "{{PROJECT_NAME}}", name)
			line = replace_all(line, "{{PROJECT_SLUG}}", slug)
			line = replace_all(line, "{{PROJECT_DESCRIPTION_SUFFIX}}", desc_suffix)
			line = replace_all(line, "{{LANG}}", lang)
			line = replace_all(line, "{{GUARD_FILE}}", guard)
			print line
		}
	' "$file" >"$file.init-tmp" && mv -- "$file.init-tmp" "$file"
done

# --- splice in the stack's blocks --------------------------------------------
# Replaces the lines strictly between two marker lines with the contents of a
# file, so the generated text lands where the template left room for it.
#
# Both markers must be present. Without this check, a missing end marker would
# silently delete everything after the begin marker — and `--force` exists, so
# that could happen to a project someone has already edited.
splice() {
	if ! grep -qxF -- "$2" "$1"; then
		die "$1 has no '$2' marker"
	fi
	if ! grep -qxF -- "$3" "$1"; then
		die "$1 has no '$3' marker"
	fi
	INIT_BEGIN="$2" INIT_END="$3" INIT_SRC="$4" \
		awk '
		BEGIN {
			begin = ENVIRON["INIT_BEGIN"]
			end = ENVIRON["INIT_END"]
			src = ENVIRON["INIT_SRC"]
		}
		$0 == begin {
			print
			while ((getline line < src) > 0) print line
			close(src)
			skipping = 1
			next
		}
		$0 == end { skipping = 0 }
		!skipping { print }
	' "$1" >"$1.init-tmp" && mv -- "$1.init-tmp" "$1"
}

splice "$target/Makefile" \
	'# === STACK ===' '# === END STACK ===' "$stacks/$lang/makefile-block.mk"
splice "$target/docs/code-standards.md" \
	'<!-- stack:begin -->' '<!-- stack:end -->' "$conventions_src"
splice "$target/.github/workflows/verify.yml" \
	'      # === toolchain ===' '      # === end toolchain ===' "$stacks/$lang/workflow-setup.yml"

# --- git ---------------------------------------------------------------------
# `-b main` because the generated workflow triggers on `main`; a default
# `master` would leave the project's first push without a CI run.
if [ "$do_git" -eq 1 ]; then
	if command -v git >/dev/null 2>&1; then
		git -C "$target" init --quiet -b main
	else
		printf 'init: git is not on PATH; skipping git init\n' >&2
	fi
fi

# --- what to do next ---------------------------------------------------------
cat <<EOF

  $name is ready at $target

  Next:
    1. cd "$target"
    2. read AGENTS.md - it is the one file that says how work happens here
    3. fill in the "This project" section at the foot of AGENTS.md
    4. make setup && make verify

  Step 4 is the contract the project has to meet. It fails on a project with
  no code yet, and that is expected: there is nothing to verify.

EOF

if [ "$lang" = other ]; then
	cat <<'EOF'
  Note: no stack block was written, because --lang other was used. Every gate
  in the Makefile fails on purpose until you fill the STACK block in. That is
  deliberate: a check that does not run must not look like one that passed.

EOF
fi
