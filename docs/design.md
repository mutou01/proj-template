# Why this template is shaped this way

A cookiecutter template organizes code for people. This one organizes **rules,
context and verification** for agents, because that is the part a code agent
cannot infer from the source tree.

The premise: an agent working in a repository knows only what it reads. If the
definition of done is unwritten, it will invent one. If the test command is
ambiguous, it will run the one that passes. If a rule is not written down, it
does not exist — no amount of convention in the team's heads reaches the
context window.

So the template is built around four claims.

## 1. Rules live in one place, and the agent is routed to them

`CLAUDE.md` is two lines of imports. `AGENTS.md` states no rules of its own —
every section says *when* to read something else. The rules themselves are in
`docs/`.

This is not tidiness for its own sake. Two forces make it necessary:

- **Drift.** A rule written twice becomes two different rules the first time
  one copy is edited.
- **Budget.** An agent loads its instruction files at startup. Codex caps the
  combined `AGENTS.md` it reads at 32 KiB and truncates past it. A file that
  outgrows the budget does not fail loudly; it gets cut off, and the rules at
  the bottom quietly stop existing.

`AGENTS.md` is therefore a router, and the test of a good router is that every
section can be written as "read X before doing Y".

## 2. Rules are earned before they are enforced

Two documents hold rules, and they are deliberately unequal.

`LESSONS.md` is the intake. Each entry is a rule, the evidence that produced
it, and how many separate *days* a review has found it. It is allowed to be
long, repetitive and tentative, because it is where a pattern is still being
noticed.

`docs/code-standards.md` is the output. A rule reaches it after being seen on
three or more separate days. There it is compressed to a single checkable line,
because from that point it is enforced.

The promotion valve is the whole design. A rule book with no intake either
stays empty — nobody wants to be the one to write the first rule — or grows
without bound until it is too long to read, at which point it is worse than
nothing, because it *looks* like it is being followed. Requiring evidence
before enforcement means every line in the standards can be traced back to
something that actually went wrong here.

An agent may propose a rule and write its evidence. A human decides whether it
belongs. The agent's output is evidence, not a verdict.

## 3. Every rule is checkable, and the gate is singular

Rules in `docs/code-standards.md` are rows in a table whose second column is
**What a reviewer looks at**. "A failed read is not an empty value" is paired
with "test with the file unreadable; a list that guards access fails closed."
A rule you cannot point at in a diff is a preference, and preferences do not
survive a deadline.

Verification is one command. `make verify` runs the format check, the linter and
the whole test suite, and CI runs the identical command. A project with three
near-synonymous test commands will eventually be checked with whichever one
passes; a project with one cannot be. Targeted tests are documented inside the
subsystem page that owns them rather than becoming build targets, because a
page explaining *why* a test exists is worth more than a target name.

The acceptance criteria require stating which checks were **not** run. A
missing line in a checklist reads as a passing line, and that is exactly how an
unverified change gets merged.

## 4. Documents have owners, and changes have triggers

`docs/subsystems/` holds one page per subsystem, in a fixed skeleton, ending in
copy-pasteable verification commands. `docs/reference.md` is the manual for
people who *use* the project. They answer different questions on different axes,
and a change can make either one wrong.

The trigger for updating them is written down: a change that alters a documented
responsibility, interface, state transition, runtime path, compatibility rule or
failure behaviour updates the owning reference **in the same change**. A change
that preserves those contracts needs no prose change.

Without a stated trigger, "update the docs" is advice, and advice loses to a
green test suite every time.

---

## Conventions the template assumes

These are not enforced by the template, but the layout reads better if they
hold. Both were taken from the project this template was extracted from.

**One concept, several small files, split by aspect.** A base file, then one
file per facet — `aside.go`, `aside_native.go`, `aside_stage.go`. Small files
are cheaper for an agent to locate and replace than one file that must be read
whole.

**A test file name is a sentence about one scenario.** Not `test_utils.py` but
`test_expired_token_is_rejected.py`. An agent searching for what covers a
behaviour is searching for that sentence, and a name that says what it checks
is the only index that cannot go stale.

**The entry point stays tiny.** `main` should parse, wire and delegate. It is
the file an agent reads first and the one where a mistake is most expensive.

## What is deliberately absent

- **Git, branch, merge and release rules.** Owned by a separate workflow skill;
  restating them per project would create a copy that drifts.
- **A community pull-request policy.** These are private projects. Revisit if
  one becomes public — see [`borrowed/magpie.md`](borrowed/magpie.md).
- **Language-specific rules baked into the template.** They are generated per
  stack at init, and labelled as a starting point to edit rather than a rule to
  inherit.

## Where each decision came from

[`borrowed/`](borrowed/README.md) records every idea this template took, where
it came from, where it landed, and — for the ones that were considered and
rejected — why. Add to it when a new source is mined.
