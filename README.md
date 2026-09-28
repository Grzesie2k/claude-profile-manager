# claude-profile-manager

A zsh shell function for managing multiple Claude Code profiles (`~/.claude-*`), with shared global config (CLAUDE.md, skills) linked automatically into each profile.

## Features

- Interactive arrow-key menu to select a profile at startup
- `--profile <name>` to skip the menu, with tab completion
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

### Skipping the menu

Pass `--profile` to launch a profile directly, without the picker:

```zsh
claude --profile private
claude --profile=work --resume
```

`--profile` is consumed by the wrapper (Claude Code has no flag of that name);
every other argument is forwarded untouched. Tab completion for profile names
is installed alongside the function.

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

## Caveat: settings.json can be shadowed

Each profile stores its options in `~/.claude-<name>/settings.json`, which Claude
Code reads as *user* settings. A `settings.json` living in the project directory
takes precedence over that file, and so can override any key a profile sets —
`statusLine`, `hooks`, `permissions`, `env`, `effortLevel`.

The case that bites in practice is a `~/.claude/settings.json` left over from a
single-account setup: launch Claude Code from your home directory and the home
directory *is* the project directory, so the leftover file wins and the profile's
own settings are silently ignored.

Keep `~/.claude/` limited to what this tool actually shares — `CLAUDE.md` and
`skills/` — and move anything per-account into the profile's own `settings.json`.

## Global config (shared across all profiles)

Place shared instructions in `~/.claude/CLAUDE.md` — it will be symlinked into every new profile.

Place global skills in `~/.claude/skills/<skill-name>/SKILL.md` — they are available in all profiles via the same symlink.

If these files don't exist when a new profile is created, empty ones are created automatically.
