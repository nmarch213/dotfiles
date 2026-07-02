#!/bin/bash
# Claude Code status line. Mirrors the compact parts of ~/.config/starship.toml.
input=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

IFS=$'\t' read -r cwd ctx_pct < <(
  printf '%s' "$input" | jq -r '
    [
      (.workspace.current_dir // .cwd // ""),
      (.context_window.used_percentage // 0 | floor)
    ] | @tsv
  ' 2>/dev/null
) || exit 0

[ -n "$cwd" ] || exit 0
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
parts+=("$(printf '%b%s%b' "$LAVENDER" "$dir_disp" "$RESET")")

# git branch
if $is_git; then
    branch=$(git branch --show-current 2>/dev/null)
    [ -n "$branch" ] || branch="$(git rev-parse --short HEAD 2>/dev/null || echo detached)"
    parts+=("$(printf '%bbranch:%s%b' "$MAUVE" "$branch" "$RESET")")

    # git status (red): modified / created / deleted counts
    status=$(git --no-optional-locks status --porcelain 2>/dev/null)
    if [ -n "$status" ]; then
        total_mod=$(echo "$status" | grep -c '^ \?M' || true)
        total_new=$(echo "$status" | grep -c '^\(??\|A \)' || true)
        deleted=$(echo "$status" | grep -c '^ \?D' || true)
        gs=""
        [ "$total_mod" -gt 0 ] && gs="${gs}!${total_mod}"
        [ "$total_new" -gt 0 ] && gs="${gs}+${total_new}"
        [ "$deleted" -gt 0 ] && gs="${gs}-${deleted}"
        [ -n "$gs" ] && parts+=("$(printf '%b%s%b' "$RED" "$gs" "$RESET")")
    fi
fi

# nodejs (green) when a package.json is present
if [ -f "package.json" ] && command -v node >/dev/null 2>&1; then
    node_version=$(node -v 2>/dev/null | sed 's/v//')
    [ -n "$node_version" ] && parts+=("$(printf '%bnode:%s%b' "$GREEN" "$node_version" "$RESET")")
fi

# context usage
if [ "$ctx_pct" -gt 0 ] 2>/dev/null; then
    if [ "$ctx_pct" -ge 80 ]; then ctx_color="$RED"
    elif [ "$ctx_pct" -ge 60 ]; then ctx_color="$YELLOW"
    else ctx_color="$BLUE"; fi
    parts+=("$(printf '%bctx:%s%%%b' "$ctx_color" "$ctx_pct" "$RESET")")
fi

IFS=' '
printf '%s\n' "${parts[*]}"
