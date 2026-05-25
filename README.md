# claude-profile-manager

A zsh shell function for managing multiple Claude Code profiles (`~/.claude-*`), with shared global config (CLAUDE.md, skills) linked automatically into each profile.

## Features

- Interactive arrow-key menu to select a profile at startup
- Add / remove profiles
- Each new profile gets a `settings.json` with sane defaults
- Shared `~/.claude/CLAUDE.md` and `~/.claude/skills/` are symlinked into every new profile automatically

## Installation

1. Copy `profile-manager.zsh` to `~/.config/claude/profile-manager.zsh`
2. Add to your `~/.zshrc`:

```zsh
source "$HOME/.config/claude/profile-manager.zsh"
```

3. Set `_CLAUDE_BIN` at the top of the file to your Claude Code binary path (default: `/opt/homebrew/bin/claude`).

## Usage

```
claude [args]
```

- **↑↓** — navigate profiles
- **Enter** — launch Claude Code with selected profile
- **+ Add account** — create a new profile and log in
- **- Remove account** — permanently delete a profile

## Global config (shared across all profiles)

Place shared instructions in `~/.claude/CLAUDE.md` — it will be symlinked into every new profile.

Place global skills in `~/.claude/skills/<skill-name>/SKILL.md` — they are available in all profiles via the same symlink.

If these files don't exist when a new profile is created, empty ones are created automatically.
