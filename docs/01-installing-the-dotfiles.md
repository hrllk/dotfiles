# Installing the Dotfiles

## 1. Overview

In this tutorial, we'll install this repository on a new Mac. We'll preview the
changes, run each bootstrap stage, and verify the result.

**The script never deletes an existing file.** It moves the file aside with a
timestamp, then puts a symlink in its place.

## 2. Prerequisites

Let's make sure the required tools are present:

```zsh
git --version && zsh --version && tmux -V && fzf --version && nvim --version
```

`oh-my-zsh` is also required. These are optional, and the configuration falls
back cleanly when they are missing: `colorls` or `eza`, `nvm`, `sdkman`,
`kubectl`, `sshpass`.

## 3. Cloning the Repository

The scripts assume `~/dotfiles`:

```zsh
git clone https://github.com/hrllk/dotfiles.git ~/dotfiles
```

## 4. Previewing the Changes

Let's start with a dry run:

```zsh
bash ~/dotfiles/scripts/bootstrap.sh --dry-run
```

`--dry-run` prints every action it would take and performs no network,
filesystem, launchctl, or secret writes.

## 5. Running the Shell Stage

Now let's run the real thing:

```zsh
bash ~/dotfiles/scripts/bootstrap.sh
```

Passing no flag is the same as `--shell-only`.

### 5.1. Cloned Plugins

The stage clones these only when the target directory is missing:

| Repository | Destination |
|---|---|
| `powerlevel10k` | `$ZSH_CUSTOM/themes/powerlevel10k` |
| `fzf-tab` | `$ZSH_CUSTOM/plugins/fzf-tab` |
| `zsh-autosuggestions` | `$ZSH_CUSTOM/plugins/zsh-autosuggestions` |
| `zsh-syntax-highlighting` | `$ZSH_CUSTOM/plugins/zsh-syntax-highlighting` |
| `tpm` | `~/.local/share/tmux/plugins/tpm` |

### 5.2. Created Symlinks

| Link | Target in the repository |
|---|---|
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.tmux.conf` | `util/tmux/.tmux.conf` |
| `~/.tmux` | `util/tmux/.tmux` |
| `~/.wezterm.lua` | `util/wezterm/wezterm.lua` |
| `$K9S_DIR/config.yaml` | `util/k9s/config.yaml` |
| `$K9S_DIR/aliases.yaml` | `util/k9s/aliases.yaml` |
| `$K9S_DIR/skins` | `util/k9s/skins` |

`$K9S_DIR` follows k9s's own resolution order: `K9S_CONFIG_DIR`, then
`XDG_CONFIG_HOME/k9s`, then `~/Library/Application Support/k9s` on macOS.

k9s writes `clusters/` and `k9s.log` itself, so neither is linked.

## 6. Running the AI Stage

The AI configuration is a separate stage:

```zsh
bash ~/dotfiles/scripts/bootstrap.sh --ai
```

This links `~/.hermes` and delegates `~/.claude` to
`ai/.claude/scripts/link-claude-home`. It cannot be combined with
`--shell-only`.

### 6.1. Preparing Codex Manually

The stage prints guidance for Codex and links nothing. The Codex local profile
holds machine-local credentials, so we create it explicitly:

```zsh
~/dotfiles/ai/.codex/init-home-codex
```

### 6.2. Syncing Hermes Secrets

Runtime secrets for the launchd gateways are a separate opt-in step:

```zsh
bash ~/dotfiles/scripts/bootstrap.sh --ai --sync-secrets
```

`--sync-secrets` requires `--ai`. See
[Loading Secrets Without Committing Them](03-loading-secrets.md).

## 7. Installing the tmux Plugins

TPM is cloned but does not install the plugins. Let's start tmux and press:

```text
prefix + I
```

## 8. Verification

Let's confirm the links landed and the shell starts fast:

```zsh
ls -l ~/.zshrc ~/.tmux.conf ~/.wezterm.lua
time zsh -i -c exit
```

Startup should land near `0.14s`. Loading the full oh-my-zsh stack instead
takes about `0.54s`.

## 9. Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `2` | Invalid flag combination, checked before any stage runs |
| `10` | Missing prerequisite or missing source directory |
| `20` | Clone or link failure |
| `30` | Hermes secret sync failure |

Run `bash scripts/bootstrap.sh --help` for the full flag list.

## 10. Conclusion

In this article, we've installed the shell, terminal, and AI configuration,
and confirmed the symlinks. The source is `scripts/bootstrap.sh`.

Next: [The Zsh Startup Sequence](02-zsh-startup-sequence.md).
