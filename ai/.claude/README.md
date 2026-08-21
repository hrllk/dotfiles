# Claude Code Configuration Guide

This directory manages Claude Code user-level configuration.

The Claude Code home directory points to this directory:

```text
~/.claude -> ~/dotfiles/ai/.claude
```

## Directory Layout

```text
.claude/
├── .gitignore                     # Runtime ignored by default; managed files are whitelisted
├── README.md                      # This guide
├── CLAUDE.md                      # Global instructions applied to every session
├── settings.json                  # User settings: theme, model, permissions, hooks, env
├── keybindings.json               # Custom key and chord bindings
├── agents/<name>.md               # Custom subagent definitions
├── commands/<name>.md             # Custom slash commands
├── output-styles/<name>.md        # Custom output styles
├── skills/<name>/                 # Own skills, excluding externally installed ones
├── hooks/                         # Hook scripts referenced from settings.json
├── plugins/config.json            # Enabled plugin selection
└── scripts/
    └── link-claude-home           # ~/.claude migration and symlink tool
```

Sessions, projects, history, caches, shell snapshots, backups, and plugin marketplace clones are not managed by Git.

## Linking ~/.claude

Run the link tool:

```sh
~/dotfiles/ai/.claude/scripts/link-claude-home
```

Preview the plan first:

```sh
~/dotfiles/ai/.claude/scripts/link-claude-home --dry-run
```

Behavior by current state of `~/.claude`:

```text
already the correct symlink  no-op
a different symlink          backed up, then relinked
a real directory             merged into this repo, backed up, then linked
```

The merge uses `rsync -a --ignore-existing`, so the versioned files in this repo win and untracked runtime state is carried over. The original directory is moved to:

```text
~/.dotfiles-backup/<timestamp>/.claude.bak.<timestamp>
```

Quit Claude Code before migrating a real directory. The tool warns when a `claude` process is running and requires confirmation to continue. `bootstrap.sh` runs the same tool, so a fresh machine needs no extra step.

After linking, review what the whitelist exposes:

```sh
git -C ~/dotfiles status --short ai/.claude
```

## Git Management Policy

`.gitignore` ignores this directory by default and whitelists only these managed entries:

- `README.md`
- `CLAUDE.md`
- `settings.json`
- `keybindings.json`
- `agents/**/*.md`
- `commands/**/*.md`
- `output-styles/*.md`
- `skills/**` documents and scripts
- `hooks/**` scripts
- `plugins/config.json`
- Operational scripts

Never commit:

- `.credentials.json` and any other credential cache
- `settings.local.json`
- `projects/`, `sessions/`, `history.jsonl`
- `shell-snapshots/`, `cache/`, `backups/`, `downloads/`, `session-env/`
- `plugins/marketplaces/`
- Machine-local state such as `policy-limits.json` and `remote-settings.json`

Externally installed skills stay untracked because their upstream tool owns them:

```text
skills/.system/
skills/gstack, skills/gstack-*, skills/_gstack-command/
```

Reinstall those through their own tool after bootstrapping a new machine, for example `/gstack-upgrade`.

## Adding a Managed File

1. Create the file under `~/.claude`, which resolves into this directory.
2. Confirm the whitelist covers it: `git -C ~/dotfiles status --short ai/.claude`.
3. If it does not appear, add a `!` entry to `.gitignore` and document it above.

Verify a specific path:

```sh
git -C ~/dotfiles check-ignore -v ai/.claude/<path>
```
