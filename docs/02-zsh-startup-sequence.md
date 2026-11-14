# The Zsh Startup Sequence

## 1. Overview

In this article, we'll follow an interactive zsh session from `~/.zshrc` to the
prompt. We'll see which module owns what, and why some tools are not loaded at
startup at all.

The goal is a prompt in about `0.14s`.

## 2. The Entry Point

`~/.zshrc` is a symlink. The real file is `zsh/.zshrc`, and it defines only two
variables and one helper:

```zsh
export DOT_PATH="$HOME/dotfiles"
export ZSH_DOTFILES_PATH="$DOT_PATH/zsh"

source_if_exists() {
  [[ -r "$1" ]] && source "$1"
}
```

Every module is loaded through `source_if_exists`, so a missing file on one
machine is not an error.

## 3. The Load Order

```text
p10k instant prompt cache
aliases/taskmaster.zsh      <- deliberately first
options/completion.zsh
options/history.zsh
env.zsh
integrations/rbenv.zsh
integrations/bun.zsh
path.zsh                    <- sole PATH owner
integrations/lazy/nvm.zsh
integrations/lazy/node-commands.zsh
secrets/index.zsh
aliases/index.zsh
integrations/lazy/sdkman.zsh
plugins/index.zsh
options/keybindings.zsh
plugins/omz/theme.zsh
```

### 3.1. Why the Taskmaster Alias Loads First

Powerlevel10k's instant prompt accepts input while the rest of the file is
still loading. If `tm` is defined after the plugin stack, a fast typist can
reach the prompt before the alias exists.

### 3.2. Why path.zsh Comes After env.zsh

`env.zsh` sets `JAVA_HOME`, `BUN_INSTALL`, and `RUBY_SHIMS_DIR`. `path.zsh`
reads those values, so it has to run later.

## 4. PATH Has One Owner

`path.zsh` is the only file that mutates `PATH` or the `path` array. The
integration modules compute values and nothing else.

It declares the array unique and appends through a guard that skips missing
directories:

```zsh
typeset -gU path

path_add() {
  local dir
  for dir in "$@"; do
    [[ -d "$dir" ]] && path+=("$dir")
  done
}
```

At the end it deduplicates, exports, and removes its own helper:

```zsh
path=("${(@u)path}")
export PATH
rehash 2>/dev/null || true
unfunction path_add 2>/dev/null
```

`unfunction` keeps `path_add` from being called later from a module that does
not own `PATH`. `zsh/tests/path-ownership-test.zsh` asserts this.

## 5. Module Ownership

| Module | Owns | Does not do |
|---|---|---|
| `options/` | Shell options, completion, keybindings | Load aliases or secrets |
| `env.zsh` | Environment variables, tool homes | Touch `PATH` |
| `path.zsh` | `PATH` and `path` | Load secrets |
| `integrations/` | Path values and hooks for rbenv, Bun | Mutate `PATH` directly |
| `integrations/lazy/` | On-demand tool init | Force-load at startup |
| `aliases/` | Short commands, work functions | Initialize plugins |
| `plugins/` | oh-my-zsh and custom plugins, theme | Set secret values |
| `secrets/` | Per-domain secret export | Commit the values |

## 6. Lazy Integrations

nvm and SDKMAN are not initialized at startup. The first `nvm`, `sdk`, or Node
command pays for it instead.

### 6.1. The Node Wrapper Prefers PATH

`integrations/lazy/node-commands.zsh` wraps the Node tools. The wrapper runs
the executable from `PATH` when one exists, and only wakes nvm when none does.

Without that order, a Homebrew-installed `task-master` would fail on a machine
with no nvm.

### 6.2. SDKMAN Fails Loudly, Not Silently

An uninstalled SDKMAN does not break startup. Calling `sdk` returns `127` with
one diagnostic line. `zsh/tests/sdkman-lazy-test.zsh` covers this.

## 7. What Startup Does Not Do

Startup loads a deterministic shell environment and nothing else. It writes no
files, makes no network calls, syncs no Hermes runtime secrets, and does not
reload itself.

Automatic reload is off unless we opt in:

```zsh
ZSH_AUTO_RELOAD=1 zsh
```

`zsh/tests/startup-isolation-test.zsh` asserts the boundary.

## 8. Conclusion

In this article, we've walked the load order, seen that `path.zsh` is the only
owner of `PATH`, and seen which tools defer their cost to first use.

Sources: `zsh/.zshrc`, `zsh/path.zsh`, `zsh/integrations/lazy/`.

Next: [Loading Secrets Without Committing Them](03-loading-secrets.md).
