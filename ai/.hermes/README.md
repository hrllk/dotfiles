# Hermes Gateway Operations Guide

This directory manages Hermes Agent configuration, profiles, and gateway runtime setup.

The Hermes home directory points to this directory:

```text
~/.hermes -> ~/dotfiles/ai/.hermes
```

## Directory Layout

```text
.hermes/
├── .env                           # Default Hermes configuration
├── .gitignore                     # Runtime ignored by default; managed files are whitelisted
├── config.yaml                    # Default profile configuration
├── profiles/<profile>/
│   ├── .env                       # Profile-specific environment configuration
│   ├── config.yaml                # Profile-specific Hermes configuration
│   └── SOUL.md                    # Profile-specific system prompt
├── bin/
│   └── gateway-<profile>          # Secret-loading wrapper executed by LaunchAgent
└── scripts/
    ├── gateway-management-profile # Interactive profile create/delete/repair tool
    ├── gateway-restart             # Gateway restart and connection verification
    └── sync-secrets                # iCloud secrets → .launchd.env synchronization
```

Sessions, logs, databases, lockfiles, caches, and gateway runtime state are not managed by Git.

## Secret Management

Discord secrets are stored in iCloud:

```text
~/Library/Mobile Documents/com~apple~CloudDocs/task/keys/personal/discord/
```

Filename convention:

```text
discord-bot-token-<profile>
discord-user-id-<name>
```

Examples:

```text
discord-bot-token-blog
discord-bot-token-jgitkins
discord-user-id-alzar
```

`sync-secrets` discovers these files and generates:

```text
~/.hermes/.launchd.env
```

`.launchd.env` is created with mode `600` and ignored by Git. launchd does not source this file automatically, so every profile gateway must run through a `bin/gateway-<profile>` wrapper.

## Adding a Profile and Bot

Run the interactive management tool:

```sh
~/.hermes/scripts/gateway-management-profile
```

Menu:

```text
1) Create
2) Delete
```

### Create

Create uses the current `hermes gateway list` output to build the `Copy from` choices.

- `none`: create a fresh profile using Hermes defaults
- an existing profile: copy that profile's settings

Enter the new profile name and Discord bot token. The script then:

1. Creates the iCloud secret file.
2. Creates the Hermes profile.
3. Binds the profile `.env` to the secret environment variable.
4. Creates a profile-specific gateway wrapper.
5. Creates the LaunchAgent plist.
6. Changes the plist to execute the wrapper instead of Python directly.
7. Synchronizes the secrets.
8. Starts and verifies the gateway.

Profile names may contain only lowercase letters, numbers, and hyphens.

### Delete

Delete uses the current gateway list to select a profile. The script confirms deletion of the profile runtime state and separately asks whether its secret file should be removed.

The `default` gateway cannot be deleted by this tool.

## Secret Rotation and Gateway Restart

After replacing an existing bot token file in iCloud, run:

```sh
~/.hermes/scripts/gateway-restart --all
```

The command performs:

```text
sync-secrets
    ↓
Restart the default gateway and every profile gateway
    ↓
Verify Discord connectivity in each gateway log
```

Restart selected profiles only:

```sh
~/.hermes/scripts/gateway-restart blog jgitkins
```

Repair an existing profile's wrapper and LaunchAgent configuration:

```sh
~/.hermes/scripts/gateway-management-profile \
  --repair blog jgitkins
```

## LaunchAgent Execution Model

Each profile has a plist at:

```text
~/Library/LaunchAgents/ai.hermes.gateway-<profile>.plist
```

The plist executes:

```text
~/.hermes/bin/gateway-<profile>
```

The wrapper:

1. Sources `~/.hermes/.launchd.env`.
2. Exports the profile-specific `DISCORD_BOT_TOKEN`.
3. Exports `DISCORD_ALLOWED_USERS`.
4. Runs `hermes_cli.main --profile <profile> gateway run --replace`.

On some macOS versions, `launchctl bootstrap` returns exit code 5. The management script falls back to `launchctl load -w` in that case.

Check LaunchAgent status:

```sh
hermes gateway list
hermes --profile blog gateway status
launchctl print "gui/$(id -u)/ai.hermes.gateway-blog"
```

## Log Inspection

Default gateway:

```sh
tail -f ~/.hermes/logs/gateway.log
```

Profile gateways:

```sh
tail -f ~/.hermes/profiles/blog/logs/gateway.log
tail -f ~/.hermes/profiles/jgitkins/logs/gateway.log
```

Successful connection logs contain:

```text
✓ discord connected
Gateway running with 1 platform(s)
```

This message indicates that the Discord adapter was not initialized:

```text
No messaging platforms enabled.
```

If it appears, check the profile wrapper and `.launchd.env` injection first.

## Reboot Behavior

`bootstrap.sh` ensures this symlink exists:

```text
~/.hermes -> ~/dotfiles/ai/.hermes
```

At login, LaunchAgent starts each gateway and the wrapper reads the persistent `.launchd.env` before injecting profile-specific environment variables.

After reboot, check:

```sh
hermes gateway list
```

To resynchronize secrets and verify every gateway:

```sh
~/.hermes/scripts/gateway-restart --all
```

## Git Management Policy

`.gitignore` ignores the Hermes directory by default and whitelists only these managed entries:

- `.env`
- `config.yaml`
- `SOUL.md`
- `README.md`
- `profiles/*/.env`
- `profiles/*/config.yaml`
- `profiles/*/SOUL.md`
- `bin/gateway-*`
- Operational scripts

Never commit:

- `.launchd.env`
- Raw Discord tokens
- Sessions
- Logs
- Databases and WAL files
- Lockfiles
- Caches and runtime state

If a token appears in logs, shell history, or diagnostic trace output, rotate it immediately in the Discord Developer Portal.
