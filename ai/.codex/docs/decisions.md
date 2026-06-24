# Decisions

Record durable project decisions here.

## 2026-05-18: Establish Codex Harness

- Created standard `scripts/bootstrap`, `scripts/check`, and `scripts/test` entrypoints.
- Added `AGENTS.md` so Codex has repository-local operating instructions.
- Kept the harness language-agnostic until a concrete project stack is introduced.

## 2026-05-18: Add Explicit Evaluation Loop

- Added `scripts/eval` to make full handoff verification a single command.
- Added `scripts/doctor` for environment and tool discovery.
- Added `harness.yml` so command names and documentation expectations are machine-readable.
- Reordered `AGENTS.md` to lead with commands and a task loop.

## 2026-05-18: Add Cross-Agent and Environment Bridges

- Added `CLAUDE.md` as a thin import bridge to avoid duplicating `AGENTS.md`.
- Added optional pre-commit hook installation through `scripts/hooks`.
- Added a minimal devcontainer that runs `scripts/bootstrap` after creation.
- Tightened GitHub Actions with read-only permissions, timeout, concurrency, and `scripts/eval`.
- Added a `justfile` as an optional task-runner facade over the canonical scripts.

## 2026-05-18: Improve Public Project Readiness

- Reworked the README opening sections to make the harness purpose, compatible agents, and standard workflow clearer.
- Added `CONTRIBUTING.md`, `CHANGELOG.md`, issue templates, and a pull request template for public collaboration.
- Left license selection as an owner decision because it affects legal reuse terms.
