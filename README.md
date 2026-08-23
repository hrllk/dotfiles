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
zsh/
  .zshrc
  env.zsh
  path.zsh
  options/
    completion.zsh
    keybindings.zsh
  integrations/
    lazy/
      nvm.zsh
      node-commands.zsh
      sdkman.zsh
  aliases/
    index.zsh
    navigation.zsh
    git.zsh
    taskmaster.zsh
    tools.zsh
    others.zsh
    work.zsh
  plugins/
    index.zsh
    custom/
      safe-paste.zsh
    omz/
      autosuggestions.zsh
      fzf-tab.zsh
      syntax-highlighting.zsh
      theme.zsh
  secrets/
    index.zsh
    _shared.zsh
    ai.zsh
    dns.zsh
    work.zsh
util/
  jetbrains/
    .ideavimrc
  kitty/
    kitty.conf
  assets/
    wallpapers/
      ...
  wezterm/
    wezterm.lua
  tmux/
    .gitmux.conf
    .tmux.conf
    .tmux/
archive/
  util/
    iterm/
      itermconf.itermexport
```

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
- `~/.config/kitty/kitty.conf` -> `~/dotfiles/util/kitty/kitty.conf`
- `~/.wezterm.lua` -> `~/dotfiles/util/wezterm/wezterm.lua`
- tmux plugins are installed under `~/.local/share/tmux/plugins/` and are not tracked in this repo
- use tmux `prefix + I` to install plugins after startup

### Post-bootstrap
- `~/.zshrc` is only an entrypoint; real shell config lives under `~/dotfiles/zsh`
- `index.zsh` files act as orchestration layers
- `source_if_exists` is used for optional local or machine-specific files
- `secrets/` is split by domain with a shared helper and a single index entrypoint
- `integrations/lazy/` contains runtime loaders that are only initialized when needed

## Documentation

- [Documentation index](docs/index.md): choose a tutorial, how-to, reference, or explanation
- [First setup tutorial](docs/tutorial-first-setup.md): install the environment on a new Mac
- [Bootstrap how-to](docs/howto-bootstrap.md): rerun, verify, and troubleshoot installation
- [Project structure reference](docs/project-structure.md): understand ownership and public shell commands
- [Configuration architecture](docs/explanation-architecture.md): understand startup order and fallbacks
- [Codex tmux unread design](docs/design-codex-tmux-unread.md): completion state in tmux windows

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
