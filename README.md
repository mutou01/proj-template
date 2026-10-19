# proj-templates

A project template for work done by code agents.

Most templates organize code for people. This one organizes the things an agent
cannot infer from the source tree: what the rules are, where to read them, what
"done" means, and which single command decides whether a change passes.

## Use it

```sh
# Git Bash, WSL, Linux, macOS
./scripts/init.sh ../my-service --name my-service --desc "Does the thing" --lang go --git
```

```powershell
# Windows PowerShell
./scripts/init.ps1 ..\my-service --name my-service --desc "Does the thing" --lang go --git
```

Both scripts take the same arguments and produce byte-identical trees. They
copy `template/` into the target, fill in the project's name, description, stack
and date, and — for a known stack — write the stack block into the `Makefile`,
the code standards and the CI workflow, so the gate is wired up and green as
soon as there is code to check.

| Option | |
| --- | --- |
| `--name <name>` | Project name as it should read in the docs. Defaults to the target directory's name. |
| `--desc "<text>"` | One line describing the project. |
| `--lang <stack>` | `go`, `python`, `ts` or `other`. Defaults to `other`. |
| `--git` | Run `git init`. Nothing is staged or committed. |
| `--force` | Write into a target directory that is not empty. |

Neither script will write into a non-empty directory without `--force`.

### What the stacks give you

| `--lang` | Gate commands | Guard file |
| --- | --- | --- |
| `go` | `go vet`, `go test`, `gofmt` | `go.mod` |
| `python` | `ruff check`, `ruff format --check`, `pytest` | `pyproject.toml` |
| `ts` | `npm run lint`, `npm run format:check`, `npm test` | `package.json` |
| `other` | nothing — every gate **fails on purpose** | `Makefile` |

`--lang other` is not a degraded mode. A gate that prints a warning and exits 0
is worse than no gate, because it makes an unrun check look like a passing one.
So an unconfigured project fails loudly until someone fills in the `STACK`
block, which is a five-minute job and is the first thing the generated
`AGENTS.md` points at.

## What you get

```
AGENTS.md                      the single source of truth: a router, not a rulebook
CLAUDE.md                      two lines: @AGENTS.md, @LESSONS.md
LESSONS.md                     what recent work got wrong, and the rule that catches it
Makefile                       one canonical gate: make verify
docs/
  code-standards.md            the rules a reviewer checks, plus the definition of done
  reference.md                 the manual for people who use the project
  subsystems/README.md         how to write and maintain a subsystem reference
  subsystems/_template.md      the skeleton to copy
.github/workflows/verify.yml   CI runs the same command you do
```

Read [`docs/design.md`](docs/design.md) for why it is shaped this way. Read
[`docs/borrowed/`](docs/borrowed/README.md) for where each idea came from,
including the ones that were considered and rejected.

## Requirements

- **`make`** — the generated project's gate is `make verify`. On Windows,
  `conda install -c conda-forge make` is the shortest path if Miniconda is
  present.
- **A POSIX shell** — the recipes need `sh`. On Windows, run make from Git Bash;
  `cmd.exe` does not understand the quoting in them.
- **`git`** — only for `--git`, and optional.

`init.sh` itself needs only `sh`, `awk`, `sed`, `find` and `cp` — no `bash`
extensions, no GNU-only flags.

## Layout

```
template/          the skeleton, copied verbatim into a new project
scripts/init.sh    create a project (POSIX sh)
scripts/init.ps1   create a project (PowerShell)
scripts/stacks/    per-language blocks spliced into the skeleton at init
docs/              why the template is shaped this way, and what it borrowed
.github/           checks the template itself
```

## Working on the template

The template is verified by being used. `template-check.yml` runs `init.sh` into
a scratch directory for each stack and asserts that no `{{PLACEHOLDER}}` survives,
that the expected files exist, and that every relative link resolves.

To check it locally:

```sh
./scripts/init.sh /tmp/probe --name probe --lang go
grep -rn '{{[A-Z_]' /tmp/probe    # must print nothing
```

Placeholders are the all-caps `{{LIKE_THIS}}` form. `${{ github.ref }}` in the
CI workflow is a GitHub Actions expression and is meant to be there.

## Adding a stack

1. `mkdir scripts/stacks/<name>`
2. Add `guard` (one line: the file that only exists in a real project of this
   kind), `makefile-block.mk`, `conventions.md` and `workflow-setup.yml` —
   copy an existing stack and edit.
3. Add `<name>` to the `case` lists in `init.sh` and `init.ps1`, and to the
   `--lang` validation in both.
