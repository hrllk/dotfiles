# References

Sources reviewed while shaping this harness:

- OpenAI, "Unrolling the Codex agent loop": https://openai.com/index/unrolling-the-codex-agent-loop/
- agents.md project: https://github.com/openai/agents.md
- SWE-bench harness documentation: https://www.swebench.com/SWE-bench/api/harness/
- SWE-agent CLI documentation: https://swe-agent.com/latest/usage/cli/
- Claude Code memory documentation: https://code.claude.com/docs/en/memory
- Cursor rules documentation: https://docs.cursor.com/context/rules-for-ai
- Dev Container specification: https://containers.dev/
- pre-commit documentation: https://pre-commit.com/
- GitHub Actions dependency caching documentation: https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching

What each source contributed:

- OpenAI documents how Codex aggregates repository instructions such as `AGENTS.md` and includes environment context.
- agents.md frames `AGENTS.md` as a predictable README-like file for coding agents.
- SWE-bench separates repository setup, environment setup, and evaluation command construction.
- SWE-agent emphasizes inspectable runs and explicit CLI entrypoints for agent workflows.
- Claude Code recommends importing `AGENTS.md` from `CLAUDE.md` when both tools are used.
- Cursor documents version-controlled, scoped project rules and also recognizes `AGENTS.md`.
- Dev Containers provide a portable way to describe a development environment.
- pre-commit provides installable Git hook stages such as pre-commit and pre-push.
- GitHub Actions documentation distinguishes reusable dependency caches from build artifacts; caching should be added when a concrete stack is present.

Applied lessons:

- Put canonical commands near the top of `AGENTS.md`.
- Keep setup, check, test, and eval commands distinct.
- Make the expected task loop explicit.
- Keep harness instructions concise enough to remain useful as the repository grows.
