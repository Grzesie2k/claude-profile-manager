# Claude Code — profile management
# Source this file from ~/.zshrc:  source "$HOME/.config/claude/profile-manager.zsh"

_CLAUDE_BIN="/opt/homebrew/bin/claude"
_CLAUDE_STATUSLINE="$HOME/.config/claude/statusline.sh"

# Generic arrow-key menu. Items prefixed with § are unselectable separators.
# All display output goes to /dev/tty; selected item is printed to stdout.
_claude_menu() {
  emulate -L zsh
  local -a items=("$@")
  local n=${#items[@]} idx=0 ni k k2 k3

  while ((idx < n)) && [[ "${items[$((idx+1))]}" == §* ]]; do ((idx++)); done

  _cm_draw() {
    local j item
    for ((j=1; j<=n; j++)); do
      item="${items[$j]}"
      if [[ "$item" == §* ]]; then
        printf "  \033[90m%s\033[0m\n" "${item#§}"
      elif ((j-1 == idx)); then
        printf "  \033[1;32m▶ %s\033[0m\n" "$item"
      else
        printf "    %s\n" "$item"
      fi
    done
  }

  trap 'tput cnorm >/dev/tty' INT
  tput civis >/dev/tty
  _cm_draw >/dev/tty

  while true; do
    IFS= read -rsk1 k </dev/tty
    if [[ "$k" == $'\x1b' ]]; then
      IFS= read -rsk1 -t 0.1 k2 </dev/tty
      IFS= read -rsk1 -t 0.1 k3 </dev/tty
      if [[ "$k2" == '[' ]]; then
        ni=$idx
        case "$k3" in
          A)
            while true; do
              ((ni--)); ((ni < 0)) && ni=$((n-1))
              [[ "${items[$((ni+1))]}" != §* ]] && break
            done
            idx=$ni
            ;;
          B)
            while true; do
              ((ni++)); ((ni >= n)) && ni=0
              [[ "${items[$((ni+1))]}" != §* ]] && break
            done
            idx=$ni
            ;;
        esac
      fi
    elif [[ "$k" == $'\n' || "$k" == $'\r' || "$k" == '' ]]; then
      break
    fi
    printf "\033[%dA" "$n" >/dev/tty
    _cm_draw >/dev/tty
  done

  tput cnorm >/dev/tty
  printf "%s\n" "${items[$((idx+1))]}"
}

_claude_add() {
  printf "\nNew profile name: " >/dev/tty
  local name
  IFS= read -r name </dev/tty
  name="${name:l}"
  name="${name// /-}"
  name="${name//[^a-z0-9-]/}"
  [[ -z "$name" ]] && return 1

  local dir="$HOME/.claude-$name"
  if [[ -d "$dir" ]]; then
    printf "Profile '%s' already exists.\n" "$name" >/dev/tty
    return 1
  fi

  mkdir -p "$dir"
  cat > "$dir/settings.json" <<EOF
{
  "permissions": { "defaultMode": "auto" },
  "skipAutoPermissionPrompt": true,
  "effortLevel": "medium",
  "env": { "HOMEBREW_NO_AUTO_UPDATE": "1" },
  "statusLine": {
    "type": "command",
    "command": "sh ${_CLAUDE_STATUSLINE} ${name}"
  }
}
EOF

  # Ensure shared global config exists, then link into new profile
  [[ -f "$HOME/.claude/CLAUDE.md" ]] || touch "$HOME/.claude/CLAUDE.md"
  [[ -d "$HOME/.claude/skills" ]] || mkdir -p "$HOME/.claude/skills"
  ln -sf "$HOME/.claude/CLAUDE.md" "$dir/CLAUDE.md"
  ln -sf "$HOME/.claude/skills" "$dir/skills"

  printf "\nProfile '%s' created. Logging in...\n" "$name" >/dev/tty
  CLAUDE_CONFIG_DIR="$dir" "$_CLAUDE_BIN" auth login
}

_claude_remove() {
  local -a profiles=("$@")
  [[ ${#profiles[@]} -eq 0 ]] && return

  printf "\nSelect profile to remove:\n" >/dev/tty
  local chosen
  chosen=$(_claude_menu "${profiles[@]}" "§──────────" "← Cancel")
  [[ "$chosen" == "← Cancel" || -z "$chosen" ]] && return

  printf "Delete '%s'? Removes ~/.claude-%s permanently. [y/N] " "$chosen" "$chosen" >/dev/tty
  local confirm
  IFS= read -r confirm </dev/tty
  if [[ "$confirm" == [yY] ]]; then
    rm -rf "$HOME/.claude-$chosen"
    printf "Profile '%s' removed.\n" "$chosen" >/dev/tty
  fi
}

claude() {
  local -a profiles=()
  for dir in "$HOME"/.claude-*/; do
    [[ -d "$dir" ]] && profiles+=("${${dir#$HOME/.claude-}%/}")
  done

  if [[ ${#profiles[@]} -eq 0 ]]; then
    printf "No profiles found.\n" >/dev/tty
    _claude_add
    return
  fi

  printf "Select Claude profile (\033[1m↑↓\033[0m move, \033[1mEnter\033[0m confirm):\n" >/dev/tty
  local chosen
  chosen=$(_claude_menu "${profiles[@]}" "§──────────" "+ Add account" "- Remove account")

  case "$chosen" in
    "+ Add account")    _claude_add ;;
    "- Remove account") _claude_remove "${profiles[@]}" ;;
    "") return 1 ;;
    *) CLAUDE_CONFIG_DIR="$HOME/.claude-$chosen" "$_CLAUDE_BIN" "$@" ;;
  esac
}
