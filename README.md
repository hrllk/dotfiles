# dotfiles

macOS personal setup: zsh, tmux, wezterm, k9s, AI tooling. Deployed as symlinks.

## Install

```zsh
git clone https://github.com/hrllk/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/bootstrap.sh --dry-run   # preview
bash ~/dotfiles/scripts/bootstrap.sh             # shell + terminal
bash ~/dotfiles/scripts/bootstrap.sh --ai        # link ~/.claude, ~/.hermes
```

`bootstrap.sh --help` for all flags. Existing files are backed up with a
timestamp, not deleted. Codex is never linked automatically; use
`ai/.codex/init-home-codex`.

Requires: `git` `zsh` `oh-my-zsh` `tmux` `fzf` `neovim`.
Optional: `colorls`/`eza` `nvm` `sdkman` `kubectl` `sshpass`.

tmux plugins install via TPM: `prefix + I` after first start.

## Layout

```text
zsh/      startup order in .zshrc; modules under options/ env/ path/ integrations/ aliases/ secrets/ plugins/
util/     tmux, wezterm, k9s, wallpapers
ai/       .claude, .codex, .hermes
scripts/  bootstrap.sh + tests
archive/  no longer loaded
```

Secret values live outside the repo under `$DOTFILES_KEY_DIR`. Tracked files
hold `${VAR}` references only.

## Docs

1. [Installing the Dotfiles](docs/01-installing-the-dotfiles.md)
2. [The Zsh Startup Sequence](docs/02-zsh-startup-sequence.md)
3. [Loading Secrets Without Committing Them](docs/03-loading-secrets.md)
4. [AI Agent Notifications in tmux](docs/04-ai-agent-notifications-in-tmux.md)
5. [The Terminal Color Palette](docs/05-the-terminal-color-palette.md)

## Verify

```zsh
time zsh -i -c exit
bash scripts/tests/bootstrap-matrix-test.sh
for t in zsh/tests/*.zsh; do zsh "$t"; done
```
