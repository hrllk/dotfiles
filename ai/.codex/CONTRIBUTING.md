# Contributing

Thanks for improving this Codex harness.

## Development Loop

Run commands from the repository root:

```sh
scripts/bootstrap
scripts/check
```

Before handing off larger changes, run:

```sh
scripts/eval
```

## Contribution Guidelines

- Keep this harness language-agnostic until a concrete stack is introduced.
- Extend the standard scripts instead of adding unrelated one-off commands.
- Update `AGENTS.md` when agent-facing instructions change.
- Update `harness.yml` when command names, document paths, or task-loop stages change.
- Record durable decisions in `docs/decisions.md`.
- Keep README changes focused on user-facing setup, workflow, and discovery.

## Pull Requests

Pull requests should include:

- A short description of the change.
- The verification command that was run.
- Any follow-up work or known limitations.
