#!/bin/bash

# Enhanced Claude Code Status Line
# Shows: context usage, file edits (M/C/D), time, directory, git, node version

# Read JSON input from stdin
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Change to the working directory
cd "$cwd" 2>/dev/null || exit 1

# ANSI Color Codes (will be dimmed in Claude Code status line)
CYAN="\033[1;36m"      # Time and directory
PURPLE="\033[1;35m"    # Git branch
YELLOW="\033[1;33m"    # Warnings/dirty
GREEN="\033[1;32m"     # Success/node
RED="\033[1;31m"       # High context usage
BLUE="\033[1;34m"      # Context usage
RESET="\033[0m"

# Get current time in HH:MM format
time_str=$(date +%H:%M)

# Get directory name
dir_name=$(basename "$cwd")

# Start output array
parts=()

# 1. CONTEXT USAGE - Show current context percentage
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))

    # Color based on usage level
    if [ $pct -ge 80 ]; then
        ctx_color="$RED"
    elif [ $pct -ge 60 ]; then
        ctx_color="$YELLOW"
    else
        ctx_color="$BLUE"
    fi

    parts+=("$(printf "${ctx_color}ctx:${pct}%%${RESET}")")
fi

# 2. FILE EDITS - Count modified, created, deleted
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Modified files (staged and unstaged)
    modified=$(git --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    staged_mod=$(git --no-optional-locks diff --cached --name-only --diff-filter=M 2>/dev/null | wc -l | tr -d ' ')
    total_mod=$((modified + staged_mod))

    # Created/new files (untracked + staged new)
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    staged_new=$(git --no-optional-locks diff --cached --name-only --diff-filter=A 2>/dev/null | wc -l | tr -d ' ')
    total_new=$((untracked + staged_new))

    # Deleted files (staged deletions)
    deleted=$(git --no-optional-locks diff --cached --name-only --diff-filter=D 2>/dev/null | wc -l | tr -d ' ')

    # Build edit summary
    edits=""
    [ $total_mod -gt 0 ] && edits="${edits}${YELLOW}M:${total_mod}${RESET} "
    [ $total_new -gt 0 ] && edits="${edits}${GREEN}C:${total_new}${RESET} "
    [ $deleted -gt 0 ] && edits="${edits}${RED}D:${deleted}${RESET} "

    if [ -n "$edits" ]; then
        parts+=("$(printf "${edits% }")")  # Remove trailing space
    fi
fi

# 3. TIME
parts+=("$(printf "${CYAN}${time_str}${RESET}")")

# 4. DIRECTORY
parts+=("$(printf "${CYAN}${dir_name}${RESET}")")

# 5. GIT BRANCH
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo "detached")
    parts+=("$(printf "${PURPLE}${branch}${RESET}")")
fi

# 6. NODE VERSION (if package.json exists)
if [ -f "package.json" ] && command -v node > /dev/null 2>&1; then
    node_version=$(node -v 2>/dev/null | sed 's/v//')
    [ -n "$node_version" ] && parts+=("$(printf "${GREEN}⬢${node_version}${RESET}")")
fi

# Join parts with " | " separator
output=""
for i in "${!parts[@]}"; do
    if [ $i -eq 0 ]; then
        output="${parts[i]}"
    else
        output="${output} | ${parts[i]}"
    fi
done

# Output the final status line
echo -e "$output"
