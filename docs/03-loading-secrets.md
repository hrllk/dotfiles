# Loading Secrets Without Committing Them

## 1. Overview

In this article, we'll see how a public repository can track `.env` files and
secret references without leaking a token.

The rule is one line: **commit the structure, keep the values outside, and link
the two by name.**

## 2. Where the Values Live

Every value lives in one file under `$DOTFILES_KEY_DIR`, outside the
repository:

```zsh
echo "$DOTFILES_KEY_DIR"
# ~/Library/Mobile Documents/com~apple~CloudDocs/task/keys
```

`zsh/secrets/_shared.zsh` sets the default and lets us override it:

```zsh
export DOTFILES_KEY_DIR="${DOTFILES_KEY_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/task/keys}"
```

One file holds one value. Syncing between machines is delegated to the
filesystem, so bootstrap never transfers a secret.

## 3. Reading a Value

`__export_secret` reads the first line of a file into a variable:

```zsh
__export_secret() {
  local name="$1"
  local path="$2"
  local value

  if [[ ! -r "$path" ]]; then
    echo "secret file not readable" >&2
    return 1
  fi

  IFS= read -r value < "$path"
  export "$name=$value"
}
```

The error message names neither the variable nor the path. That is deliberate:
the message can end up in a log. The cost is that diagnosing it means checking
the key directory by hand.

## 4. Most Loaders Are Functions

`zsh/secrets/` is split by domain, and `index.zsh` is the only entry point:

| File | Loader | Runs |
|---|---|---|
| `_shared.zsh` | defines `__export_secret` | at startup |
| `ai.zsh` | `load_ai_keys` | when called |
| `dns.zsh` | `load_dns_keys` | when called |
| `work.zsh` | `load_work_keys`, `load_oke_vars` | when called |
| `personal.zsh` | none | **at startup** |

### 4.1. Why Deferred

Two reasons. Reading twelve files from an iCloud path at startup is slow,
especially before the files have synced down. And a datacenter password should
not sit in the environment of every shell and every child process; with a
loader, `DC_TRB_PRD` is exported only while `godcprd` runs.

### 4.2. Loading Everything at Once

```zsh
load_all_keys
```

It probes each loader before calling it, so a machine missing a domain file
still succeeds:

```zsh
load_all_keys() {
  typeset -f load_ai_keys >/dev/null 2>&1 && load_ai_keys
  typeset -f load_dns_keys >/dev/null 2>&1 && load_dns_keys
  typeset -f load_work_keys >/dev/null 2>&1 && load_work_keys
  typeset -f load_oke_vars >/dev/null 2>&1 && load_oke_vars
}
```

`personal.zsh` exports at the top level and is not covered by `load_all_keys`.
So the name overstates the scope, and a missing key directory prints
`secret file not readable` three times on every new shell.

## 5. The launchd Path

A gateway started by launchd inherits no login shell, so it cannot see what
`zsh/secrets/` exported. `ai/.hermes/scripts/sync-secrets` writes a file
instead.

### 5.1. The Variable Name Comes From the File Name

```text
discord-bot-token-graphkeeper  ->  DISCORD_BOT_TOKEN_GRAPHKEEPER
discord-user-id-alzar          ->  DISCORD_USER_ID_ALZAR
```

One name decides the key file, the environment variable, the `.env` reference,
and the wrapper's export line. Adding a profile wires nothing by hand.

### 5.2. The Write Is Defensive

```zsh
umask 077
tmp_file="$(mktemp "${TARGET}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT
...
grep -q '^export DISCORD_USER_ID_ALZAR=' "$tmp_file"
grep -q '^export DISCORD_BOT_TOKEN_DEFAULT=' "$tmp_file"
chmod 600 "$tmp_file"
mv -f "$tmp_file" "$TARGET"
trap - EXIT
```

The `mktemp` plus `mv -f` pair makes the replacement atomic, so a partially
written file is never readable. The `grep` checks run before the move, so a
failed sync leaves the previous file intact.

Only two variables are verified. The rest surface at gateway start.

## 6. Tracked Files Hold References, Not Values

This is the part that makes committing safe:

```env
DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN_GRAPHKEEPER}
DISCORD_ALLOWED_USERS=${DISCORD_USER_ID_ALZAR}
```

The file records that this profile uses the graphkeeper token. It does not
record what that token is.

The wrapper refuses to start without a value:

```zsh
set -eu
[[ -r "$LAUNCHD_ENV" ]]
source "$LAUNCHD_ENV"
export DISCORD_BOT_TOKEN="$DISCORD_BOT_TOKEN_GRAPHKEEPER"
[[ -n "$DISCORD_BOT_TOKEN" && -n "$DISCORD_ALLOWED_USERS" ]]
```

Under `set -eu` a failed `[[ ]]` ends the script. An explicit failure in the
launchd log beats an auth-failure loop.

## 7. The gitignore Is an Allowlist

AI tool directories mix configuration with runtime state, credential caches
included, and each update adds new files. A denylist loses that race.

So `ai/.claude`, `ai/.codex`, and `ai/.hermes` invert it:

```gitignore
*

!.gitignore
!settings.json
!skills/**/*.md
```

Ignore is the default, and we name what to track. A new file is ignored, so a
mistake becomes an omission rather than a leak.

### 7.1. The Cost

New files under `ai/` do not appear in `git status`. After adding one, we add
a `!` line to that directory's `.gitignore`:

```zsh
git check-ignore -v ai/.codex/skills/my-skill/SKILL.md
```

## 8. Conclusion

In this article, we've seen values kept outside the repository, loaders
deferred until a command needs them, a name-derivation rule that wires new
profiles automatically, and an allowlist that fails toward omission.

Sources: `zsh/secrets/`, `ai/.hermes/scripts/sync-secrets`, `ai/*/.gitignore`.

Next: [AI Agent Notifications in tmux](04-ai-agent-notifications-in-tmux.md).
