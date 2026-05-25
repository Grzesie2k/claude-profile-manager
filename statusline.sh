#!/bin/sh
# Usage: sh statusline.sh <profile-name>
profile="${1:-default}"
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

home="$HOME"
short_cwd=$(echo "$cwd" | sed "s|^$home|~|")

git_branch=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

make_bar() {
  pct=$(printf '%.0f' "$1")
  filled=$(( pct / 10 ))
  empty=$(( 10 - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  i=0
  while [ $i -lt $empty ]; do bar="${bar}░"; i=$(( i + 1 )); done
  echo "[${bar}] ${pct}%"
}

fmt_tokens() {
  n=$1
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    printf '%.1fM' "$(echo "$n" | awk '{printf "%.1f", $1/1000000}')"
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    printf '%.1fk' "$(echo "$n" | awk '{printf "%.1f", $1/1000}')"
  else
    echo "$n"
  fi
}

prompt=$(printf '\033[32mλ\033[0m %s/' "$short_cwd")

if [ -n "$git_branch" ]; then
  prompt="$prompt \033[33m($git_branch)\033[0m"
fi

prompt="$prompt  \033[90m${profile}\033[0m"

if [ -n "$model" ]; then
  prompt="$prompt \033[36m$model\033[0m"
fi

if [ -n "$used" ]; then
  bar=$(make_bar "$used")
  prompt="$prompt \033[35mctx:${bar}\033[0m"
fi

if [ -n "$total_in" ] && [ -n "$total_out" ]; then
  in_fmt=$(fmt_tokens "$total_in")
  out_fmt=$(fmt_tokens "$total_out")
  prompt="$prompt \033[90m↑${in_fmt} ↓${out_fmt}\033[0m"
fi

if [ -n "$rl_5h" ]; then
  bar=$(make_bar "$rl_5h")
  prompt="$prompt \033[33m5h:${bar}\033[0m"
fi

if [ -n "$rl_7d" ]; then
  bar=$(make_bar "$rl_7d")
  prompt="$prompt \033[33m7d:${bar}\033[0m"
fi

printf "%b\n" "$prompt"
