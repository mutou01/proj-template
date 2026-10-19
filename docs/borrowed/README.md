# Borrowed ideas

Every structural decision in this template came from somewhere. This directory
records where, so that a rule can be traced back to the evidence that earned
it, and so that a later reader can tell a deliberate choice from an accident.

It also records the ideas that were **considered and rejected**. Those are the
more useful half: without them, the same idea gets proposed again every few
months, and gets re-litigated from scratch each time.

## The format

One file per source project, named after the project. Each entry has four
parts, plus an optional short note after the status where the idea needs one:

```markdown
### <The idea, as a claim>

- **Source:** <file, page or anchor in the source project — and the specific
  thing in it, not the whole document>
- **The idea:** <two or three sentences. What it actually is, and what it is
  for. Enough that a reader who never opens the source can judge it.>
- **Landed:** <the file in this template that carries it, or `nothing`>
- **Status:** adopted | adapted | rejected

<For `adapted`: what was changed and why.>
<For `rejected`: what would have to be true for it to be worth revisiting.>
```

Keep the entries in the order they appear in the source where that makes
sense, and group them under `## Adopted`, `## Adapted` and `## Rejected`.

## What belongs here

A record of an idea and its fate — not a summary of the project. If an entry
could have been written without reading the source, it is not worth keeping:
"good error handling" is not an idea, "a failed read is never an empty value,
because the two are different facts and code that conflates them fails open"
is.

## Index

| Project | Language | Analysed | Entries |
| --- | --- | --- | --- |
| [magpie](magpie.md) | Go | 2026-10-19 | 21 adopted, 4 adapted, 3 rejected |

## Adding a source

1. Read the project's agent-facing files first — `AGENTS.md`, `CLAUDE.md`,
   `LESSONS.md`, `CONTRIBUTING`, and whatever else it tells its own
   contributors. They are where a project states the rules it actually runs on,
   and they are usually more honest than its README.
2. Read its build and CI configuration. What a project checks on every change
   is a better statement of its values than anything it writes about them.
3. Write the entries. Record the rejections as carefully as the adoptions.
4. Add a row to the index above.

The point is not to converge on one project's conventions. It is to be able to
say, for each rule in this template, who earned it and how.
