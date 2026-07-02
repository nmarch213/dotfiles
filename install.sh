#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
NVM_VERSION="${NVM_VERSION:-v0.40.5}"
PACKAGES=(agents zsh git starship ghostty tmux nvim ssh fonts)
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

install_claude_code() {
  if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
    return
  fi

  log "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
}

install_opencode() {
  if command -v opencode >/dev/null 2>&1 || [ -x "$HOME/.opencode/bin/opencode" ]; then
    return
  fi

  log "Installing opencode..."
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
    log "Installing nvm $NVM_VERSION..."
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi

  nvm install --lts
}

# --- Prerequisites ---

# Xcode CLI tools
if ! xcode-select -p &>/dev/null; then
  log "Installing Xcode CLI tools..."
  xcode-select --install
  echo "Re-run this script after Xcode CLI tools finish installing."
  exit 0
fi

# Homebrew
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Detect prefix for both Intel and Apple Silicon
  if [ -d /opt/homebrew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# --- Packages ---

log "Installing brew packages..."
brew bundle --file="$DOTFILES/Brewfile"

# --- Stow ---

log "Stowing configs..."
cd "$DOTFILES"

if ! stow -nvR "${PACKAGES[@]}"; then
  echo ""
  echo "Stow found conflicts. Back up or move the listed files, then rerun this script."
  echo "This script avoids --adopt so it does not overwrite existing machine-local config."
  exit 1
fi

stow -vR "${PACKAGES[@]}"

log "Linking Claude agent files..."
replace_with_symlink "../AGENTS.md" "$HOME/.claude/CLAUDE.md"
replace_with_symlink "$DOTFILES/claude/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
ensure_claude_settings

# --- Rust ---

if ! command -v rustup &>/dev/null; then
  log "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env" 2>/dev/null || true
rustup update stable

# --- Node ---

install_nvm_and_node

# pnpm via corepack
if ! command -v pnpm &>/dev/null; then
  log "Installing pnpm..."
  corepack enable
  corepack prepare pnpm@latest --activate
fi

# --- Agent CLIs ---

install_claude_code
install_opencode

# --- tmux plugins ---

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  log "Updating tmux plugins..."
  tmux start-server \; source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 || true
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
else
  log "Installing tpm + plugins..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  tmux start-server \; source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 || true
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

# --- macOS defaults ---

log "Applying macOS defaults..."
bash "$DOTFILES/macos.sh"

# --- Done ---

echo ""
log "Done!"
echo ""
echo "Manual steps:"
echo "  1. Restart terminal"
echo "  2. Install Wispr Flow (Mac App Store)"
echo "  3. Sign into: Arc, Raycast, Spotify, Slack, Obsidian, etc."
echo "  4. Copy SSH keys from secure backup or generate new:"
echo "     ssh-keygen -t ed25519 -C \"n.march213@gmail.com\""
echo "     gh auth login"
echo "  5. Import Raycast settings"
echo "  6. Open nvim — LazyVim will auto-install plugins on first launch"
