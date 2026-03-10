#!/bin/bash

input=$(cat)

# Parse all needed fields in one jq call
eval "$(echo "$input" | jq -r '
  "cwd=\(.workspace.current_dir)",
  "ctx_input=\(.context_window.current_usage.input_tokens // 0)",
  "ctx_cache_create=\(.context_window.current_usage.cache_creation_input_tokens // 0)",
  "ctx_cache_read=\(.context_window.current_usage.cache_read_input_tokens // 0)",
  "ctx_size=\(.context_window.context_window_size // 0)"
')"

cd "$cwd" 2>/dev/null || exit 1

CYAN="\033[1;36m"
PURPLE="\033[1;35m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
RESET="\033[0m"

parts=()

# Context usage
if [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    pct=$(( (ctx_input + ctx_cache_create + ctx_cache_read) * 100 / ctx_size ))
    if [ $pct -ge 80 ]; then ctx_color="$RED"
    elif [ $pct -ge 60 ]; then ctx_color="$YELLOW"
    else ctx_color="$BLUE"; fi
    parts+=("$(printf "${ctx_color}ctx:${pct}%%${RESET}")")
fi

# Git info (single rev-parse, single status call)
is_git=false
git rev-parse --git-dir >/dev/null 2>&1 && is_git=true

if $is_git; then
    # One git status call for all file counts
    status=$(git --no-optional-locks status --porcelain 2>/dev/null)
    if [ -n "$status" ]; then
        total_mod=$(echo "$status" | grep -c '^ \?M' || true)
        total_new=$(echo "$status" | grep -c '^\(??\|A \)' || true)
        deleted=$(echo "$status" | grep -c '^ \?D' || true)

        edits=""
        [ "$total_mod" -gt 0 ] && edits="${edits}${YELLOW}M:${total_mod}${RESET} "
        [ "$total_new" -gt 0 ] && edits="${edits}${GREEN}C:${total_new}${RESET} "
        [ "$deleted" -gt 0 ] && edits="${edits}${RED}D:${deleted}${RESET} "
        [ -n "$edits" ] && parts+=("$(printf "${edits% }")")
    fi
fi

# Time + directory
parts+=("$(printf "${CYAN}$(date +%H:%M)${RESET}")")
parts+=("$(printf "${CYAN}$(basename "$cwd")${RESET}")")

# Git branch
if $is_git; then
    branch=$(git branch --show-current 2>/dev/null || echo "detached")
    parts+=("$(printf "${PURPLE}${branch}${RESET}")")
fi

# Node version
if [ -f "package.json" ] && command -v node >/dev/null 2>&1; then
    node_version=$(node -v 2>/dev/null | sed 's/v//')
    [ -n "$node_version" ] && parts+=("$(printf "${GREEN}⬢${node_version}${RESET}")")
fi

# Join with " | "
IFS=' | ' ; echo -e "${parts[*]}"
