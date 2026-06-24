#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
PACKAGES=(agents zsh git starship ghostty tmux nvim)
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

log() { echo "==> $1"; }

replace_with_symlink() {
  local link_target="$1"
  local link_path="$2"

  mkdir -p "$(dirname "$link_path")"

  if [ -L "$link_path" ]; then
    if [ "$(readlink "$link_path")" = "$link_target" ]; then
      return
    fi
    rm "$link_path"
  elif [ -e "$link_path" ]; then
    local backup
    backup="$link_path.backup.$(date +%Y%m%d%H%M%S)"
    mv "$link_path" "$backup"
    log "Backed up existing $link_path to $backup"
  fi

  ln -s "$link_target" "$link_path"
}

install_tmux_plugins() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [ ! -d "$tpm_dir" ]; then
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  tmux start-server \; source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 || true
  "$tpm_dir/bin/install_plugins"
}

install_claude_code() {
  if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
    return
  fi

  curl -fsSL https://claude.ai/install.sh | bash
}

install_opencode() {
  if command -v opencode >/dev/null 2>&1 || [ -x "$HOME/.opencode/bin/opencode" ]; then
    return
  fi

  curl -fsSL https://opencode.ai/install | bash
}

if ! command -v brew >/dev/null 2>&1; then
  log "Homebrew is required. Install it first, then rerun this script."
  exit 1
fi

log "Installing missing dev packages without upgrading existing packages..."
brew bundle --file="$DOTFILES/Brewfile.dev" --no-upgrade

log "Installing missing agent CLIs..."
install_claude_code
install_opencode

log "Checking Stow conflicts..."
cd "$DOTFILES"
if ! stow -nvR "${PACKAGES[@]}"; then
  echo ""
  echo "Stow found conflicts. Back up or move the listed files, then rerun this script."
  echo "This script avoids --adopt so it does not overwrite existing machine-local config."
  exit 1
fi

log "Stowing dev configs..."
stow -vR "${PACKAGES[@]}"

log "Linking Claude agent files..."
replace_with_symlink "../AGENTS.md" "$HOME/.claude/CLAUDE.md"
replace_with_symlink "../.dotfiles/claude/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

log "Installing tmux plugins..."
install_tmux_plugins

log "Done."
