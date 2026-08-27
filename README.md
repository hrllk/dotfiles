# Dotfiles

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Structure](#structure)
- [Quickstart](#quickstart)
- [Documentation](#documentation)
- [Performance](#performance)
- [Conventions](#conventions)
- [Notes](#notes)

## Overview
This repository contains a personal dotfiles setup for shell, editor, and terminal tooling.

The layout is optimized for:
- fast interactive shell startup
- clear ownership boundaries
- safe bootstrapping with backups
- local overrides without polluting the main configuration

## Features
- `zsh`: thin entrypoint, modular options, lazy tool integrations, aliases, secrets, and plugin loading
- `ai`: secret loading for AI and API tooling
- `util`: editor and terminal-related configs, including tmux, Kitty, wezterm, and JetBrains-related files

## Structure
```text
ai/
  .claude/       Claude settings and home-link helper
  .codex/        Codex harness, hooks, and local setup
  .hermes/       Hermes profiles, gateways, and sync scripts
archive/         historical configuration only
docs/            tutorials, how-tos, references, explanations
scripts/         bootstrap entrypoint and regression tests
util/            JetBrains, Kitty, tmux, WezTerm, assets
zsh/             startup orchestration and shell modules
.taskmaster/     task graph and planning metadata
```

Active configuration lives under `ai/`, `util/`, and `zsh/`. Runtime state such as logs, caches, databases, sessions, and heartbeat files is not part of the documented source layout. `archive/` is historical data and is not loaded during startup.

## Quickstart
### Prerequisites
Required:
- `git`
- `bash`
- `zsh`
- `oh-my-zsh`
- `neovim`
- `tmux`
- `fzf`

Optional:
- `colorls` or `eza`
- `kubectl`
- `sshpass`
- `nvm`
- `sdkman`

### Bootstrap
```zsh
git clone https://github.com/hrllk/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/bootstrap.sh
```

The bootstrap script supports explicit stages:
- `--shell-only` (the default when no option is provided): clones shell/terminal plugins, creates backups, and links shell/terminal configuration
- `--ai`: links Claude and Hermes configuration and prints Codex local-profile guidance without copying or linking Codex files
- `--ai --sync-secrets`: runs the explicit Hermes runtime secret synchronization step
- `--dry-run`: previews the selected stage without network, filesystem, launchctl, or secret writes
- invalid flag combinations exit with code `2` before any stage runs

The bootstrap script:
- clones `powerlevel10k`, `fzf-tab`, `zsh-autosuggestions`, and `zsh-syntax-highlighting` when missing
- clones tmux plugin manager (TPM) when missing
- backs up existing shell and terminal config files with a shared invocation timestamp
- creates symlinks for `zsh`, `ideavim`, `tmux`, `gitmux`, `kitty`, and `wezterm`
- keeps shell secret loading separate from Hermes runtime synchronization

Targets after bootstrap:
- `~/.zshrc` -> `~/dotfiles/zsh/.zshrc`
- `~/.ideavimrc` -> `~/dotfiles/util/jetbrains/.ideavimrc`
- `~/.tmux.conf` -> `~/dotfiles/util/tmux/.tmux.conf`
- `~/.gitmux.conf` -> `~/dotfiles/util/tmux/.gitmux.conf`
- `~/.tmux` -> `~/dotfiles/util/tmux/.tmux`
- `~/.config/kitty/kitty.conf` -> `~/dotfiles/util/kitty/kitty.conf`
- `~/.wezterm.lua` -> `~/dotfiles/util/wezterm/wezterm.lua`
- the `--ai` stage can link `~/.claude` and `~/.hermes`
- Codex is never copied or linked automatically; prepare it explicitly with `ai/.codex/init-home-codex`
- tmux plugins are installed under `~/.local/share/tmux/plugins/` and are not tracked in this repo
- use tmux `prefix + I` to install plugins after startup

### Post-bootstrap
- `~/.zshrc` is only an entrypoint; real shell config lives under `~/dotfiles/zsh`
- `index.zsh` files act as orchestration layers
- `source_if_exists` is used for optional local or machine-specific files
- `secrets/` is split by domain with a shared helper and a single index entrypoint
- `integrations/lazy/` contains runtime loaders that are only initialized when needed

## Documentation

Start at the [documentation index](docs/index.md), or jump straight to a quadrant.

**Tutorial**
- [First setup](docs/tutorial-first-setup.md): install the environment on a new Mac

**How-to**
- [Bootstrap](docs/howto-bootstrap.md): rerun, verify, and troubleshoot installation
- [Add configuration](docs/howto-add-configuration.md): add an alias, module, secret domain, or Hermes profile

**Reference**
- [Project structure](docs/project-structure.md): directory ownership and deployment paths
- [Shell commands](docs/reference-shell-commands.md): every alias, function, lazy wrapper, and key binding
- [Bootstrap CLI](docs/reference-bootstrap-cli.md): flags, environment variables, exit codes
- [Hermes gateways](docs/reference-hermes-gateways.md): profiles, wrappers, launchd wiring

**Explanation**
- [Configuration architecture](docs/explanation-architecture.md): startup order and fallbacks
- [Secret handling](docs/explanation-secret-handling.md): why tracked `.env` files carry no secrets

**Design and review**
- [AI agent tmux unread design](docs/design-codex-tmux-unread.md): shared Codex/Claude Code completion state in tmux windows
- [Structural review (2026-08-26)](docs/review-structural-2026-08-26.md): known structural issues and change candidates

### Verification
```zsh
time zsh -i -c exit
```

Measured on this machine:
- current setup: `real 0.14s`, `user 0.04s`, `sys 0.03s`
- full oh-my-zsh load: `real 0.54s`, `user 0.22s`, `sys 0.22s`

The comparison is directional, but it shows the cost of loading the full OMZ stack.

## Conventions
- `~/.zshrc` is only an entrypoint; real shell config lives under `~/dotfiles/zsh`
- `index.zsh` files act as orchestration layers
- `source_if_exists` is used for optional local or machine-specific files
- `secrets/` is split by domain with a shared helper and a single index entrypoint
- `integrations/lazy/` contains runtime loaders that are only initialized when needed

## Notes
- `zsh` initialization is intentionally modular to keep interactive startup lightweight
- `ll` uses `colorls` when available, and falls back to standard directory listings if it is not
- `archive/util/iterm/` keeps historical iTerm export data out of the active config set
- `env.zsh` prefers `~/.sdkman/candidates/java/current` for Java when SDKMAN is installed, and otherwise falls back to `java_home -v 17` when available
- `path.zsh` owns PATH construction and is loaded after `env.zsh` so it can use the environment values defined there
- after `sdk default java <version>`, `which java` should resolve to `~/.sdkman/candidates/java/current/bin/java`
- If you move to another machine, split machine-specific overrides into `env.local.zsh`
- The current layout is optimized for this machine, not for full portability
