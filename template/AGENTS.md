# Notes for coding agents

This file is the entry point for how to work in this repository. Other tools'
agent files import it — `CLAUDE.md` here, and whatever your tool reads. Edit
this file, not those.

("Source of truth" is used elsewhere in these docs for a narrower thing: the
file, table or setting that decides a subsystem's behaviour. This file is not
that; it is a router.)

Keep it short. It is a router: each section says *when* to read something, not
what the something says. A rule that belongs in a linked document and is copied
here instead will drift out of date.

## Before you change code

Read [LESSONS.md](LESSONS.md) and the [code standards](docs/code-standards.md).
The lessons are what recently merged work got wrong and the rule that would
have caught it. The standards are what a reviewer checks, rule by rule. Both
are short, and reading them is cheaper than the rework they prevent.

## Subsystems

Before changing a documented subsystem, read its
[design reference](docs/subsystems/README.md) and verify the linked source. The
reference describes the contracts the subsystem currently keeps; the code is
the implementation of them.

When a change alters a documented responsibility, interface, state transition,
runtime path, compatibility rule or failure behaviour, update the owning
reference in the same change. An internal refactor that preserves those
contracts needs no prose change.

## Verification

`make verify` is the gate. It runs the format check, the linter, the build and
the whole test suite. CI's `verify` job runs the same command, so the code
checks are identical.

CI also has a separate `docs` job that checks local links. `make verify` does
not run it, so a green local gate does not guarantee a green CI — follow the
links in your change, or let CI tell you.

Nothing else is a gate. A command that is not part of `verify` is a
convenience, not evidence.

What "done" means — including the checks you must report as *not* run — is in
[Acceptance criteria](docs/code-standards.md#acceptance-criteria).

## Documentation

`docs/subsystems/` describes how the project works, one page per subsystem.
`docs/reference.md` is the manual for people who *use* the project. They answer
different questions and are organized on different axes; a change can make
either wrong. Fix it in the same change.

## This project

<!-- Filled in when this project was created. Keep this section short: what
     this is, where the entry point is, and which subsystems exist. It is the
     only part of this file that is about this project rather than about
     working here. -->

- **{{PROJECT_NAME}}**{{PROJECT_DESCRIPTION_SUFFIX}}
- Stack: {{LANG}}
- Entry point: <!-- e.g. `cmd/{{PROJECT_SLUG}}/main.go`, `src/index.ts` -->
- Build output: <!-- where build and package put their artifacts -->

### Subsystems

<!-- One line per page under docs/subsystems/, each linked. Start with the one a
     new change is most likely to touch. Delete this comment when you add the
     first row. Written without link syntax so that the link checker, which
     cannot tell an example from a broken link, stays useful. -->

<!-- | Subsystem | Reference | -->
<!-- | --- | --- | -->
<!-- | <what it does> | docs/subsystems/<name>.md | -->
