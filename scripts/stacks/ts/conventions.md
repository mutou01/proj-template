### TypeScript / Node

Starting points. Edit them.

- The `package.json` scripts `build`, `test`, `lint`, `format` and
  `format:check` are what the Makefile calls. Keep them working — a script that
  the Makefile names and `package.json` does not define fails the gate with a
  confusing error.
- `format:check` must exit non-zero on unformatted code (Prettier's
  `--check`, Biome's `format --check`). A script that rewrites files and exits
  0 is not a check.
- Strict TypeScript. `any` needs a comment saying why, and `@ts-expect-error`
  needs one saying what is being suppressed.
- No floating promises: every promise is awaited, returned, or explicitly
  marked with `void` and a reason. An unhandled rejection is a crash on a
  timing you do not control.
- Validate data at the boundary — anything parsed from JSON, a request, a file
  or an environment variable — and keep it typed after that. `as` at a boundary
  is a claim, not a check.
- A failed read throws. It does not resolve to `undefined`, `[]` or `""` as if
  the value were empty; "could not read" and "read, and it was empty" are
  different facts.
- Tests name the behaviour they check, one behaviour per test file where the
  runner allows it. Prefer the runtime's own runner (`node --test`) over a
  framework unless the project already has one.
- Tests never reach the network: record the response once and serve it from a
  fixture.
