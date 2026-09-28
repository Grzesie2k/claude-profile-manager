# Claude Code — profile management
# Source this file from ~/.zshrc:  source "$HOME/.config/claude/profile-manager.zsh"

_CLAUDE_BIN="${_CLAUDE_BIN:-$(command -v claude 2>/dev/null || echo /opt/homebrew/bin/claude)}"
_CLAUDE_STATUSLINE="$HOME/.config/claude/statusline.sh"

# Generic arrow-key menu. Items prefixed with § are unselectable separators.
# All display output goes to /dev/tty; selected item is printed to stdout.

_claude_menu_draw() {
  local -a items=("$@")
  local n=${#items[@]} idx="${_CLAUDE_MENU_IDX:-0}" j item
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

_claude_menu() {
  emulate -L zsh
  local -a items=("$@")
  local n=${#items[@]} idx=0 ni k k2 k3

  while ((idx < n)) && [[ "${items[$((idx+1))]}" == §* ]]; do ((idx++)); done

  trap 'tput cnorm >/dev/tty; trap - INT' INT
  tput civis >/dev/tty
  _CLAUDE_MENU_IDX=$idx _claude_menu_draw "${items[@]}" >/dev/tty

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
    _CLAUDE_MENU_IDX=$idx _claude_menu_draw "${items[@]}" >/dev/tty
  done

  tput cnorm >/dev/tty
  trap - INT
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
    local target="$HOME/.claude-$chosen"
    if [[ "$target" == "$HOME/.claude-"* && -d "$target" ]]; then
      rm -rf "$target"
      printf "Profile '%s' removed.\n" "$chosen" >/dev/tty
    fi
  fi
}

# Lists profile names (dirs ~/.claude-<name> containing settings.json).
_claude_profiles() {
  local dir
  for dir in "$HOME"/.claude-*/; do
    # Only real profiles (created by _claude_add) have a settings.json;
    # this skips unrelated dirs like ~/.claude-squad.
    [[ -d "$dir" && -f "$dir/settings.json" ]] && printf "%s\n" "${${dir#$HOME/.claude-}%/}"
  done
}

_claude_run() {
  local name="$1"; shift
  local dir="$HOME/.claude-$name"
  if [[ ! -f "$dir/settings.json" ]]; then
    printf "Unknown profile '%s'. Available: %s\n" "$name" "${(j:, :)${(f)"$(_claude_profiles)"}}" >&2
    return 1
  fi
  CLAUDE_CONFIG_DIR="$dir" "$_CLAUDE_BIN" "$@"
}

claude() {
  emulate -L zsh
  local profile="" arg
  local -a args=()

  # --profile is consumed here (claude has no such flag of its own);
  # everything else is forwarded untouched.
  while (( $# )); do
    arg="$1"
    case "$arg" in
      --profile)
        [[ -z "$2" ]] && { printf "--profile requires a name\n" >&2; return 1; }
        profile="$2"; shift 2 ;;
      --profile=*)
        profile="${arg#--profile=}"; shift ;;
      --)
        args+=("$@"); shift $#; break ;;
      *)
        args+=("$arg"); shift ;;
    esac
  done

  if [[ -n "$profile" ]]; then
    _claude_run "$profile" "${args[@]}"
    return
  fi

  local -a profiles=("${(@f)$(_claude_profiles)}")
  profiles=("${(@)profiles:#}")

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
    *) _claude_run "$chosen" "${args[@]}" ;;
  esac
}

# Completion for --profile values; other args fall through to claude's own
# completion if one is installed.
_claude_complete() {
  if [[ "${words[CURRENT-1]}" == --profile ]]; then
    compadd -- ${(f)"$(_claude_profiles)"}
    return
  fi
  compadd -- --profile
  _default
}
compdef _claude_complete claude 2>/dev/null
