#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
NVM_VERSION="${NVM_VERSION:-v0.40.5}"
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

ensure_claude_settings() {
  local claude_dir="$HOME/.claude"
  local settings="$claude_dir/settings.json"
  local default_settings="$DOTFILES/claude/.claude/settings.json"
  local status_command="/bin/bash ~/.claude/statusline-command.sh"

  mkdir -p "$claude_dir"

  if [ ! -e "$settings" ]; then
    ln -s "$default_settings" "$settings"
    return
  fi

  if [ -L "$settings" ]; then
    case "$(readlink "$settings")" in
      "$default_settings" | "../.dotfiles/claude/.claude/settings.json")
        return
        ;;
      *)
        log "Preserving existing symlinked Claude settings at $settings"
        return
        ;;
    esac
  fi

  if ! jq empty "$settings" >/dev/null 2>&1; then
    local backup
    backup="$settings.backup.$(date +%Y%m%d%H%M%S)"
    mv "$settings" "$backup"
    ln -s "$default_settings" "$settings"
    log "Backed up invalid Claude settings to $backup"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  jq --arg command "$status_command" \
    '.statusLine = {"type": "command", "command": $command}' \
    "$settings" >"$tmp"

  if cmp -s "$tmp" "$settings"; then
    rm "$tmp"
  else
    mv "$tmp" "$settings"
    log "Updated existing Claude settings statusLine"
  fi
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

install_nvm_and_node() {
  export NVM_DIR="$HOME/.nvm"

  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  local installed_version=""
  if command -v nvm >/dev/null 2>&1; then
    installed_version="$(nvm --version)"
  fi

  if [ "$installed_version" != "${NVM_VERSION#v}" ]; then
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi

  nvm install --lts
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

log "Installing Node LTS via nvm..."
install_nvm_and_node

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
replace_with_symlink "$DOTFILES/claude/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
ensure_claude_settings

log "Installing tmux plugins..."
install_tmux_plugins

log "Done."
