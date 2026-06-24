#!/bin/bash
# Claude Code status line — mirrors ~/.config/starship.toml
# Layout: directory(lavender)  branch(mauve)  git_status(red)  nodejs(green)  ctx
input=$(cat)

# Parse all needed fields in one jq call
eval "$(echo "$input" | jq -r '
  "cwd=\(.workspace.current_dir // .cwd // "")",
  "ctx_input=\(.context_window.current_usage.input_tokens // 0)",
  "ctx_cache_create=\(.context_window.current_usage.cache_creation_input_tokens // 0)",
  "ctx_cache_read=\(.context_window.current_usage.cache_read_input_tokens // 0)",
  "ctx_size=\(.context_window.context_window_size // 0)"
')"

cd "$cwd" 2>/dev/null || exit 0

# Starship palette (256-color approximations of Catppuccin lavender/mauve)
LAVENDER="\033[1;38;5;183m"
MAUVE="\033[1;38;5;177m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

parts=()

# directory: truncation_length=3, truncate_to_repo=true
is_git=false
git rev-parse --git-dir >/dev/null 2>&1 && is_git=true

if $is_git; then
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    repo_name=$(basename "$repo_root")
    rel=${cwd#"$repo_root"}
    rel=${rel#/}
    if [ -n "$rel" ]; then dir_path="$repo_name/$rel"; else dir_path="$repo_name"; fi
else
    dir_path="$cwd"
fi
# keep last 3 path components
dir_disp=$(echo "$dir_path" | awk -F'/' '{ n=NF; s=(n>3)?n-2:1; out=""; for(i=s;i<=n;i++){ out=(out==""?$i:out"/"$i) } print out }')
parts+=("$(printf "${LAVENDER}%s${RESET}" "$dir_disp")")

# git branch (mauve, leading branch glyph)
if $is_git; then
    branch=$(git branch --show-current 2>/dev/null || echo "detached")
    parts+=("$(printf "${MAUVE}\xee\x82\xa0 %s${RESET}" "$branch")")

    # git status (red): modified / created / deleted counts
    status=$(git --no-optional-locks status --porcelain 2>/dev/null)
    if [ -n "$status" ]; then
        total_mod=$(echo "$status" | grep -c '^ \?M' || true)
        total_new=$(echo "$status" | grep -c '^\(??\|A \)' || true)
        deleted=$(echo "$status" | grep -c '^ \?D' || true)
        gs=""
        [ "$total_mod" -gt 0 ] && gs="${gs}!${total_mod}"
        [ "$total_new" -gt 0 ] && gs="${gs}+${total_new}"
        [ "$deleted" -gt 0 ] && gs="${gs}\xe2\x9c\x98${deleted}"
        [ -n "$gs" ] && parts+=("$(printf "${RED}${gs}${RESET}")")
    fi
fi

# nodejs (green) when a package.json is present
if [ -f "package.json" ] && command -v node >/dev/null 2>&1; then
    node_version=$(node -v 2>/dev/null | sed 's/v//')
    [ -n "$node_version" ] && parts+=("$(printf "${GREEN}\xee\x98\x99 %s${RESET}" "$node_version")")
fi

# context usage (Claude-specific; Starship has no equivalent)
if [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    pct=$(( (ctx_input + ctx_cache_create + ctx_cache_read) * 100 / ctx_size ))
    if [ "$pct" -ge 80 ]; then ctx_color="$RED"
    elif [ "$pct" -ge 60 ]; then ctx_color="$YELLOW"
    else ctx_color="$BLUE"; fi
    parts+=("$(printf "${ctx_color}ctx:%s%%${RESET}" "$pct")")
fi

IFS=' '
echo -e "${parts[*]}"
