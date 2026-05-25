# claude-profile-manager

A zsh shell function for managing multiple Claude Code profiles (`~/.claude-*`), with shared global config (CLAUDE.md, skills) linked automatically into each profile.

## Features

- Interactive arrow-key menu to select a profile at startup
- Add / remove profiles
- Each new profile gets a `settings.json` with sane defaults
- Shared `~/.claude/CLAUDE.md` and `~/.claude/skills/` are symlinked into every new profile automatically

## Installation

```zsh
curl -fsSL https://raw.githubusercontent.com/Grzesie2k/claude-profile-manager/main/install.sh | zsh
```

Then restart your shell or `source ~/.zshrc`.

The installer:
- Downloads `profile-manager.zsh` and `statusline.sh` to `~/.config/claude/`
- Creates `~/.claude/skills/` and `~/.claude/CLAUDE.md` if they don't exist
- Adds the `source` line to `~/.zshrc` (idempotent — safe to run again)

**Note:** `_CLAUDE_BIN` auto-detects your Claude Code binary via `command -v claude`. Override by setting it before sourcing the file if needed.

## Usage

```
claude [args]
```

- **↑↓** — navigate profiles
- **Enter** — launch Claude Code with selected profile
- **+ Add account** — create a new profile and log in
- **- Remove account** — permanently delete a profile

## Status bar

`statusline.sh` renders a prompt line shown in Claude Code's status bar. It displays:

- Current working directory (with `~` shortening)
- Git branch
- Active profile name
- Model name
- Context window usage bar
- Token counts (input/output)
- Rate limit usage bars (5h and 7d)

Each profile's `settings.json` points to `statusline.sh <profile-name>` so the profile name is always visible in the bar.

## Global config (shared across all profiles)

Place shared instructions in `~/.claude/CLAUDE.md` — it will be symlinked into every new profile.

Place global skills in `~/.claude/skills/<skill-name>/SKILL.md` — they are available in all profiles via the same symlink.

If these files don't exist when a new profile is created, empty ones are created automatically.
