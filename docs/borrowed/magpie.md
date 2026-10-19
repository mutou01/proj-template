# magpie

- **Source:** <https://github.com/yetone/magpie>
- **Analysed:** 2026-10-19, against `main`
- **What it is:** a local model-routing gateway and menu-bar app in Go — it lets
  any coding agent (Claude Code, Codex, Gemini CLI, OpenCode) run against any
  provider or subscription, and moves to the next account when a quota runs
  out. ~5,500 files, 16.7k stars, released many times a day.
- **Why it was worth mining:** its README says the code is "written, reviewed,
  merged and released by agents", and its repository is organized around that
  claim rather than merely permitting it. It is a project whose *process* has
  been under load — 2,277 test files, a nightly review loop, releases measured
  in hours — so its conventions have already survived contact with reality.

No commit is pinned. The repository moves too fast for one to stay meaningful,
and every idea below is a structural choice that has been stable across many
releases rather than a line of code that could change tomorrow.

---

## Adopted

### The agent instructions are a loader and a router, not a rulebook

- **Source:** `CLAUDE.md` (23 bytes, its entire contents) and `AGENTS.md`.
- **The idea:** `CLAUDE.md` contains nothing but `@AGENTS.md` and
  `@LESSONS.md` — two imports. `AGENTS.md` is the real entry point, and it
  states no rules of its own: every section says only *when* to read something
  ("Before changing a documented subsystem, read its design reference…"). The
  heavy material lives in linked documents, read on demand.
- **Landed:** `template/CLAUDE.md`, `template/AGENTS.md`
- **Status:** adopted

Two things follow from this, and both matter. The rules cannot drift, because
they exist in exactly one file. And the context an agent loads at startup stays
small — which is not a nicety: Codex caps the combined `AGENTS.md` it will read
at 32 KiB, and a file that exceeds a tool's budget gets silently truncated
rather than rejected.

### A lessons log whose rules graduate into the standards

- **Source:** `LESSONS.md`, and the `## Moved to the code standards` section at
  its foot.
- **The idea:** every entry is a rule, the evidence that earned it, and a
  `Seen N× (dates)` tally. `Seen` counts the *days* a review found the same
  rule. At three separate days the rule is promoted into `code-standards.md`
  and the evidence stays behind in the log.
- **Landed:** `template/LESSONS.md`, `template/docs/code-standards.md`
- **Status:** adopted

This is the single best idea in the repository. A rule book with no intake
process either stays empty or grows until nobody reads it. The promotion valve
does both jobs at once: rules have to be earned before they are enforced, and
the log stays short enough to read before every change. It also produces a
genuinely useful artifact — a standards document where every line has a
provenance.

### Every rule is written so a reviewer can check it

- **Source:** `docs/code-standards.md`. Every rule is a row in a
  `Rule | What a reviewer looks at` table.
- **The idea:** the second column is not a rationale, it is an *instruction for
  the person reviewing*. "A fix reaches every sibling of the bug" is paired
  with "grep for the same pattern: every agent, subcommand, guard of the same
  shape and caller of a changed predicate." A rule that cannot be pointed at in
  a diff is not a rule, it is a preference.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### The definition of done requires declaring what was *not* run

- **Source:** `docs/code-standards.md`, `## Acceptance criteria`.
- **The idea:** "Say which ones were run and what they printed. A check that
  wasn't run is listed as not run, never left out." A missing line in a
  checklist reads as a passing line, and that is precisely how an unverified
  change gets merged.
- **Landed:** `template/docs/code-standards.md`, section
  `## Acceptance criteria`
- **Status:** adopted

This is the most directly agent-facing rule in the whole repository. An agent
that has just written a change is the worst possible judge of whether it needs
verification, and "not run" is a cheap, checkable thing to require.

### A subsystem reference has a fixed skeleton, including its own verification commands

- **Source:** `docs/subsystems/` — 14 pages, from 6 KB to 225 KB, all following
  the same shape: responsibilities and boundaries → source of truth → runtime
  paths → state transitions → constraints and failure behaviour → verification.
- **The idea:** the design document is not prose about the code. It is a
  contract, in fixed sections, ending in commands a reader can paste. Each page
  names the tests that exercise it, so a reader can run them before and after a
  change.
- **Landed:** `template/docs/subsystems/_template.md`,
  `template/docs/subsystems/README.md`
- **Status:** adopted

### "Source of truth" is a named thing

- **Source:** `docs/subsystems/README.md`, and every page under it.
- **The idea:** each page names, explicitly, the file or setting that decides
  the subsystem's behaviour — so that when the page and the code disagree, the
  reader knows which one is wrong. The phrase is used consistently enough to be
  a term of art.
- **Landed:** `template/docs/subsystems/_template.md`
- **Status:** adopted

### One canonical gate; targeted tests are not build targets

- **Source:** the `Makefile`. `make test` is `go vet ./... && go test ./...`;
  there is no `lint`, `verify` or `fmt` target, and no target per test.
- **The idea:** a project with several near-synonymous test commands will
  eventually be checked with whichever one passes. So there is exactly one gate
  command, and it is the same command CI runs. Individual tests are documented
  inside the subsystem page that owns them, as copy-pasteable commands, rather
  than exploded into dozens of build targets nobody maintains.
- **Landed:** `template/Makefile`, `template/docs/subsystems/_template.md`
- **Status:** adopted

### The build file refuses to run in the wrong directory

- **Source:** the top of the `Makefile` — an `ifeq` on the module line in
  `go.mod` that calls `$(error …)`.
- **The idea:** recipes name paths relative to the working folder, and `clean`
  deletes them. `make -f path/to/Makefile` from elsewhere would therefore act
  on the wrong tree. The guard makes that impossible rather than unlikely.
- **Landed:** `template/Makefile`
- **Status:** adapted — the guard is keyed to a per-stack marker file
  (`go.mod`, `pyproject.toml`, `package.json`) chosen at init, so it works for
  every stack the template supports rather than only Go.

### Non-obvious build and CI lines carry the reason they exist

- **Source:** the `Makefile` and `.github/workflows/test.yml` throughout. The
  version sanitizer explains which shell metacharacters it strips; the Linux-only
  formatting check explains that Windows checks out CRLF; the Windows test steps
  explain why they run a targeted list instead of the suite.
- **The idea:** the comment answers *why this line exists*, often naming the
  incident that added it. That is what stops a later reader from "simplifying" a
  line whose purpose they cannot see.
- **Landed:** `template/Makefile`, `template/.github/workflows/verify.yml`,
  `scripts/stacks/*/makefile-block.mk`
- **Status:** adopted

### A test that cannot fail is not evidence

- **Source:** `docs/code-standards.md`, `## Tests`.
- **The idea:** "Put the old code back and run the test; it must fail, with a
  real failure that names the behaviour. A compile error or a skipped test does
  not count." The reviewer, not the author, does the reverting.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### A fix reaches every sibling of the bug

- **Source:** `docs/code-standards.md`, `## What a change contains`.
- **The idea:** the most-repeated lesson in the repository. "Grep for the same
  pattern: every agent, subcommand, guard of the same shape and caller of a
  changed predicate gets the fix in the same change." One incident produced six
  follow-up releases because each fix covered only the case in the report.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### A failed read is never an empty value

- **Source:** `docs/code-standards.md`, `## What a change contains`.
- **The idea:** "A failed read, parse or hash means 'unknown'. It never means
  'empty', 'none' or 'equal'." The evidence is a security failure: an IP allow
  list read an unreadable settings file as an empty list and admitted every
  address. Access-guarding structures must fail closed.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### Tests never reach the network, and never touch the real machine

- **Source:** `docs/code-standards.md`, `## Tests`, and the acceptance criteria.
- **The idea:** a remote response is served from bytes recorded from the real
  one; a dependency comes from a lock file, not from whatever the registry
  serves today; tests run under a temporary home directory and never read a
  real credential or config.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### Run the whole suite, not the packages you think you touched

- **Source:** `docs/code-standards.md`, `## Tests`.
- **The idea:** guard tests live in packages a change did not touch — which is
  exactly why they catch it. Selecting packages by intuition defeats them.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### A default never overrides a value the user set

- **Source:** `docs/code-standards.md`, `## What a change contains`.
- **The idea:** before writing a setting, find everywhere it is read, and test
  with a user-set value present. A migration that rewrites a setting names the
  users who set it themselves, or says in the release notes why it does not.
  The evidence includes a default that overrode a user's own value for roughly
  150 releases.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### Nothing that can block runs under a lock its reader needs

- **Source:** `docs/code-standards.md`, `## What a change contains`.
- **The idea:** a named, checkable concurrency rule. Locks are where a change
  looks obviously correct and behaves badly under load, so the rule is phrased
  as something a reviewer can trace rather than as a principle.
- **Landed:** `template/docs/code-standards.md`
- **Status:** adopted

### The user manual and the design references are different documents

- **Source:** `docs/reference.md` (185 KB) alongside `docs/subsystems/`.
- **The idea:** the manual is organized by what a *user* touches — install,
  providers, options, files — and is written for them. The subsystem pages are
  organized by what the *code* owns and are written for whoever changes it. Two
  audiences, two organizing axes, two documents.
- **Landed:** `template/docs/reference.md`
- **Status:** adopted

### The lessons log records how far it has been reviewed

- **Source:** line 1 of `LESSONS.md`:
  `<!-- reviewed-through: e297a8ab2 (2026-10-13 23:30 +0800) -->`
- **The idea:** a review process that runs periodically needs to know where it
  stopped. Without the marker, each pass either re-reads everything or silently
  skips a stretch.
- **Landed:** `template/LESSONS.md`
- **Status:** adopted

### An agent proposes; a human decides

- **Source:** `docs/contributors.md`: "An agent only proposes. It writes the
  evidence (PR numbers, dates, what was wrong) to the maintainer; the maintainer
  decides."
- **The idea:** the automation boundary is stated explicitly, and the agent's
  output is *evidence* rather than a verdict. Applied to the lessons log: an
  agent may propose a rule and write its evidence; a human decides whether it
  belongs and decides every promotion into the standards.
- **Landed:** `template/LESSONS.md`
- **Status:** adapted — the community-PR policy that surrounds it was not
  taken (see Rejected), but this rule was kept and moved into the lessons log,
  where it governs the log's own maintenance.

### Line endings are enforced by the repository, not by each contributor

- **Source:** `.gitattributes`. A single `* text=auto eol=lf`, with a comment
  explaining that guard tests parse source files line by line and that a
  Windows checkout with `autocrlf` on turned four of them red.
- **The idea:** fix the checkout once, in the repository, rather than asking
  every contributor to configure their machine correctly.
- **Landed:** `template/.gitattributes`
- **Status:** adopted

### CI cancels superseded pull-request runs but never a main run

- **Source:** `.github/workflows/test.yml`, the `concurrency` block:
  `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`.
- **The idea:** a new push to a pull request makes the previous run's answer
  irrelevant. A run on `main` is the answer a release waits for, so it is never
  cancelled — "a release waits for a green run."
- **Landed:** `template/.github/workflows/verify.yml`
- **Status:** adopted

### Architectural rules are enforced by tests, not by prose

- **Source:** guard tests scattered through the tree —
  `TestMovedBuiltinsSayTheirPlugin` (every retired built-in must carry a notice
  naming the plugin that replaced it), `TestFolderVarsAreListed`,
  `TestNoCommandBypassesProc`, core-script size budgets, and i18n-key checks.
- **The idea:** a convention that can be asserted is asserted, and the prose
  merely points at the test. A written rule is read once and then forgotten; a
  failing test is not. The suite becomes the enforcement mechanism for the
  architecture, not just for behaviour.
- **Landed:** `template/docs/code-standards.md`, section
  `## Rules that can be a test`
- **Status:** adopted

This is the idea that makes the rest of the rules stick. A standards document
tells a reviewer what to look for; a guard test tells the change itself, before
anyone reviews it.

### A failing matrix entry must not hide the others

- **Source:** `.github/workflows/test.yml`, `strategy: fail-fast: false`.
- **The idea:** with a matrix, stopping at the first failure means one broken
  platform hides the state of the rest, and the next run discovers them one at
  a time.
- **Landed:** `template/.github/workflows/verify.yml`
- **Status:** adopted

---

## Adapted

### The gate is `make verify`, not `make test`

- **Source:** the `Makefile`, where `make test` folds `go vet` in and there is
  no separate verification target.
- **The idea:** one canonical command, but magpie names it after the test
  suite, because for a single-language project the two are nearly the same
  thing.
- **Landed:** `template/Makefile`
- **Status:** adapted

A language-agnostic template cannot assume the test runner is also the linter
or the formatter. `verify` is the honest name for "everything a change must
pass", and it gives CI one stable name to call regardless of what is underneath
it. This is a deliberate divergence from the source, not an oversight.

### The folder guard is keyed per stack

- **Source:** the `Makefile` guard, which reads the module line from `go.mod`.
- **Landed:** `template/Makefile`, `scripts/stacks/*/guard`
- **Status:** adapted — init writes the marker file for the chosen stack, so
  the same guard works for Python and Node. The behaviour is unchanged; only
  what it looks for differs.

---

## Rejected

### The community pull-request harm and block policy

- **Source:** `docs/contributors.md`.
- **The idea:** a three-tier inbound-PR policy — a stop list of diff shapes
  that halt review before anyone evaluates what the change does (anything
  touching release scripts, credentials, or adding a network address); a
  category closed without a full review; and numeric criteria for blocking an
  author, kept in live tables with the evidence attached.
- **Landed:** nothing, except the "agent proposes, human decides" rule, which
  was moved into `template/LESSONS.md`.
- **Status:** rejected

It is a good document, and it is specifically a document for a popular public
repository absorbing unsolicited pull requests at volume. These projects are
private, and a policy for triaging strangers would be dead weight that reads as
ceremony. **Worth revisiting** if any project in this template becomes public
and starts receiving outside contributions — at which point the useful part to
recover is the ordering: decide whether a change could cause harm *before*
deciding whether it is good.

### Git, branch and commit conventions

- **Source:** `docs/code-standards.md` `## Commits`, and the session and
  worktree isolation rule ("a checkout, a worktree and the logs in it belong to
  the session that made them").
- **The idea:** commit subjects name an area and then what the user now sees,
  written as plain behaviour; the body says how it was verified and which test
  fails without the change; concurrent agent sessions work in their own
  worktrees and never clean another session's.
- **Landed:** nothing in `template/`. The commit-message convention was kept in
  `template/docs/code-standards.md`, because it is also the place a reviewer
  looks for the evidence the acceptance criteria require.
- **Status:** rejected

The user's own `git-workflow` skill owns branching, merging, releases and
hotfixes, and a second statement of the same rules in every generated project
would be a copy that drifts from the original. **Worth revisiting** if a
project ever needs to work without that skill present.

The worktree-isolation rule is the part most worth recovering, if concurrent
agent sessions ever become normal here: it is the difference between two agents
working in parallel and two agents corrupting each other's checkout.

### Language-specific rule sections

- **Source:** `docs/code-standards.md` `## Go` and `## GUI`.
- **The idea:** a short section of rules that only make sense in that
  language or framework — `any` over `interface{}`; every user-visible string
  goes through the translation function; use the app's own dropdown rather than
  a native `<select>`.
- **Landed:** `scripts/stacks/<stack>/conventions.md`, written into
  `docs/code-standards.md` at init.
- **Status:** adapted

The structure was kept — a project-specific section at the foot of the
standards — but the content is generated per stack, and the generated text is
explicitly labelled a starting point for the project to edit rather than a rule
it inherits.

### A model-driven UI preview attached to every pull request

- **Source:** `.github/ui-preview/` (8 files) and `.github/workflows/ui-preview.yml`.
- **The idea:** when a pull request touches the UI, CI builds it in a fresh
  home filled with synthetic data, gives a model the diff, has it plan a set of
  scenes — what to click, hover and type — then drives the real app in a
  browser, drawing a pointer and its trail, and attaches screenshots (and a
  video when the change spans pages) to the pull request description. The
  security split is the careful part: the job that runs a stranger's code holds
  the API key but no write access, and the job that writes never runs the code.
- **Landed:** nothing.
- **Status:** rejected

It is a genuinely clever harness, and it is the right answer to a specific
problem: reviewing a visual change by reading a diff. It is also several
hundred lines of infrastructure that only pays for itself on a project with a
GUI, a real browser test suite, and inbound pull requests from people the
maintainer does not know.

**Worth revisiting** for a project that has a user interface and a browser test
suite — at which point the two things to take are the security split, and the
rule that everything is thrown away if a credential appears on screen.
