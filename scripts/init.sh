#!/usr/bin/env sh
#
# init.sh — create a project from this template.
#
#   scripts/init.sh <target-dir> --name <name> [--desc "<one line>"]
#                                 [--lang go|python|ts|other] [--git] [--force]
#
# Copies template/ into <target-dir> and fills in the project's name,
# description, stack and date. For a known stack it also writes the stack block
# into the Makefile, the code standards and the CI workflow, so `make verify`
# works on the first run.
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

  --name <name>     Project name, as it should read in the docs. Defaults to
                    the target directory's name.
  --desc "<text>"   One line describing the project.
  --lang <stack>    go | python | ts | other. Defaults to other, which leaves
                    the gate failing until you fill it in.
  --git             Run `git init` in the new project. Nothing is staged or
                    committed — that is yours to decide.
  --force           Write into a target directory that is not empty.
  -h, --help        This text.

Examples:
  scripts/init.sh ../my-service --name my-service --desc "Does the thing" --lang go --git
  scripts/init.sh ./scratch --name scratch --lang python
EOF
}

# --- arguments ---------------------------------------------------------------
target=''
name=''
desc=''
lang='other'
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

today=$(date +%Y-%m-%d)
guard=$(tr -d ' \t\r\n' <"$stacks/$lang/guard")
[ -n "$guard" ] || die "$stacks/$lang/guard is empty"

# `&` and `\` are special in an awk replacement, so a project name containing
# either would corrupt the file instead of appearing in it.
escape_awk() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g'; }

name_esc=$(escape_awk "$name")
slug_esc=$(escape_awk "$slug")
desc_esc=$(escape_awk "$desc")
lang_esc=$(escape_awk "$lang_label")
today_esc=$(escape_awk "$today")
guard_esc=$(escape_awk "$guard")

# --- copy --------------------------------------------------------------------
cp -R -- "$template/." "$target/"

# --- substitute the placeholders ---------------------------------------------
# Only the files the template ships. A file added to template/ later is picked
# up without editing this script.
find "$target" -type f -not -path '*/.git/*' -print | while IFS= read -r file; do
	awk -v name="$name_esc" -v slug="$slug_esc" -v desc="$desc_esc" \
		-v lang="$lang_esc" -v date="$today_esc" -v guard="$guard_esc" '
		{
			gsub(/\{\{PROJECT_NAME\}\}/, name)
			gsub(/\{\{PROJECT_SLUG\}\}/, slug)
			gsub(/\{\{PROJECT_DESCRIPTION\}\}/, desc)
			gsub(/\{\{LANG\}\}/, lang)
			gsub(/\{\{DATE\}\}/, date)
			gsub(/\{\{GUARD_FILE\}\}/, guard)
			print
		}
	' "$file" >"$file.init-tmp" && mv -- "$file.init-tmp" "$file"
done

# --- splice in the stack's blocks --------------------------------------------
# Replaces the lines strictly between two marker lines with the contents of a
# file, so the generated text lands where the template left room for it and the
# script stays idempotent if it is ever run twice.
splice() {
	awk -v begin="$2" -v end="$3" -v src="$4" '
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
	'<!-- stack:begin -->' '<!-- stack:end -->' "$stacks/$lang/conventions.md"
splice "$target/.github/workflows/verify.yml" \
	'      # === toolchain ===' '      # === end toolchain ===' "$stacks/$lang/workflow-setup.yml"

# --- git ---------------------------------------------------------------------
if [ "$do_git" -eq 1 ]; then
	if command -v git >/dev/null 2>&1; then
		git -C "$target" init --quiet
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

EOF

if [ "$lang" = other ]; then
	cat <<'EOF'
  Note: no stack block was written, because --lang other was used. Every gate
  in the Makefile fails on purpose until you fill the STACK block in. That is
  deliberate: a check that does not run must not look like one that passed.

EOF
fi
