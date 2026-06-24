# Workflow

## Starting Work

Run:

```sh
scripts/bootstrap
```

Then inspect the repository and confirm the intended change.

For local hook installation, run:

```sh
scripts/hooks
```

## During Work

- Keep task notes in `tasks/` when context would otherwise be lost.
- Prefer small, reviewable commits.
- Update `docs/decisions.md` for decisions future agents should preserve.

## Finishing Work

Run:

```sh
scripts/eval
```

Use `scripts/check` for faster inner-loop verification and `scripts/eval` before
handoff. If either command cannot run, document why in the final handoff.

## Adding a New Stack

When adding a language or framework:

1. Add the dependency manifest normally.
2. Extend `scripts/bootstrap` for installation.
3. Extend `scripts/check` for lint, format, type, and test commands.
4. Extend `scripts/test` for the focused test command.
5. Update `harness.yml` if command names or expectations change.
6. Add CI caching only when there is a concrete dependency manager and lockfile.
