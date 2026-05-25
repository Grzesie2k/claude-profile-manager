#!/usr/bin/env zsh
set -euo pipefail

REPO="Grzesie2k/claude-profile-manager"
RAW="https://raw.githubusercontent.com/$REPO/main"
DEST="$HOME/.config/claude/profile-manager.zsh"
STATUSLINE_DEST="$HOME/.config/claude/statusline.sh"
ZSHRC="$HOME/.zshrc"
SOURCE_LINE='source "$HOME/.config/claude/profile-manager.zsh"'

print_step() { printf "\033[1;34m▶\033[0m %s\n" "$1"; }
print_ok()   { printf "\033[1;32m✓\033[0m %s\n" "$1"; }
print_warn() { printf "\033[1;33m!\033[0m %s\n" "$1"; }

# Check dependencies
for cmd in curl zsh; do
  if ! command -v "$cmd" &>/dev/null; then
    printf "\033[1;31m✗\033[0m Required command not found: %s\n" "$cmd" >&2
    exit 1
  fi
done

# Download scripts
print_step "Downloading profile-manager.zsh and statusline.sh..."
mkdir -p "${DEST:h}"
curl -fsSL "$RAW/profile-manager.zsh" -o "$DEST"
curl -fsSL "$RAW/statusline.sh" -o "$STATUSLINE_DEST"
chmod +x "$STATUSLINE_DEST"
print_ok "Saved to ${DEST:h}/"

# Create shared global config structure
print_step "Setting up shared config..."
mkdir -p "$HOME/.claude/skills"
[[ -f "$HOME/.claude/CLAUDE.md" ]] || touch "$HOME/.claude/CLAUDE.md"
print_ok "~/.claude/skills/ and ~/.claude/CLAUDE.md ready"

# Add source line to .zshrc if not already present
print_step "Checking ~/.zshrc..."
if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
  print_warn "Already sourced in $ZSHRC — skipping"
else
  printf '\n# Claude Code profile manager\n%s\n' "$SOURCE_LINE" >> "$ZSHRC"
  print_ok "Added source line to $ZSHRC"
fi

printf "\n\033[1mDone!\033[0m Restart your shell or run:\n"
printf "  source ~/.zshrc\n\n"
printf "Then type \033[1mclaude\033[0m to select a profile.\n"
