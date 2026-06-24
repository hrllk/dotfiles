# Harness for Codex

A language-agnostic repository harness for OpenAI Codex, coding agents,
Claude Code, and Cursor. It provides durable `AGENTS.md` instructions,
standard automation entrypoints, task templates, verification scripts, and
lightweight workflow docs for agent-driven software work.

Use this repository as a Codex harness, `AGENTS.md` template, or reusable
coding-agent project scaffold when you want every future task to start from a
predictable baseline:

- one place for agent instructions through `AGENTS.md`
- one bootstrap command
- one check command
- one test command
- one full evaluation command
- optional hooks and devcontainer metadata
- lightweight documentation for decisions and tasks

## Use Cases

- Start a new repository with Codex-ready agent instructions.
- Standardize coding-agent workflows across OpenAI Codex, Claude Code, and Cursor.
- Give automation agents stable commands for setup, checks, tests, and handoff evaluation.
- Keep project decisions and task briefs in predictable locations.
- Add a language stack later without replacing the harness contract.

## Quick Start

```sh
scripts/bootstrap
scripts/check
scripts/doctor
```

## What This Provides

- `AGENTS.md`: repository-local operating instructions for Codex and compatible agents.
- `CLAUDE.md`: Claude Code bridge that imports the shared `AGENTS.md` guidance.
- `scripts/bootstrap`: dependency preparation when a known stack is present.
- `scripts/check`: lint, format, type, and test checks when available.
- `scripts/test`: focused test-suite entrypoint.
- `scripts/eval`: complete handoff verification through doctor, bootstrap, and check.
- `tasks/TEMPLATE.md`: task brief template for work that needs durable context.
- `docs/decisions.md`: durable decisions future agents should preserve.

## Workflow

1. Write the task brief in `tasks/` when the work needs context.
2. Implement changes in the relevant project files.
3. Record durable decisions in `docs/decisions.md`.
4. Run `scripts/check` before finishing.

## Automation Entrypoints

- `scripts/bootstrap`: install or prepare dependencies when a known stack is present.
- `scripts/check`: run formatting, linting, type checks, and tests when available.
- `scripts/test`: run the test suite when available.
- `scripts/eval`: run `doctor`, `bootstrap`, and `check` as a handoff gate.
- `scripts/doctor`: print repository and tooling readiness.
- `scripts/hooks`: install optional local hooks through `pre-commit`.

If you use `just`, the same commands are exposed in [`justfile`](justfile):

```sh
just check
just eval
```

These scripts are safe defaults for an empty or early-stage repository. Extend
them as the project grows.

## Compatible Agents

- OpenAI Codex reads `AGENTS.md` for repository instructions.
- Cursor can use `AGENTS.md` as shared project guidance.
- Claude Code reads `CLAUDE.md`, which imports the same shared instructions.

Keep shared rules in `AGENTS.md` so agent behavior stays consistent across
tools. Add tool-specific notes only when a tool requires a different bridge.

## Harness Metadata

[`harness.yml`](harness.yml) records the canonical command names, expected
documentation files, and task-loop stages. Keep it aligned with `AGENTS.md` and
the scripts in this repository.

## Optional Environment

The repository includes a minimal [dev container](.devcontainer/devcontainer.json)
that runs `scripts/bootstrap` after creation. It is optional; local development
works without Docker.
