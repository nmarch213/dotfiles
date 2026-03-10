#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

log() { echo "==> $1"; }

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

# Files that should never be overwritten if they already exist
SKIP_IF_EXISTS=(
  "$HOME/.claude/settings.json"
)

# Temporarily move protected files aside
for f in "${SKIP_IF_EXISTS[@]}"; do
  if [ -f "$f" ] && [ ! -L "$f" ]; then
    mv "$f" "${f}.bak"
  fi
done

for pkg in zsh git starship ghostty tmux nvim ssh claude fonts; do
  if [ -d "$pkg" ]; then
    stow -v --adopt "$pkg" 2>/dev/null || stow -v "$pkg"
  fi
done
# Reset any adopted diffs back to repo versions
git checkout -- .

# Restore protected files (overwrite the symlink)
for f in "${SKIP_IF_EXISTS[@]}"; do
  if [ -f "${f}.bak" ]; then
    rm -f "$f"
    mv "${f}.bak" "$f"
    log "Preserved existing $(basename "$f")"
  fi
done

# --- Rust ---

if ! command -v rustup &>/dev/null; then
  log "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env" 2>/dev/null || true
rustup update stable

# --- Node ---

# nvm
if [ ! -d "$HOME/.nvm" ]; then
  log "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# pnpm via corepack
if ! command -v pnpm &>/dev/null; then
  log "Installing pnpm..."
  corepack enable
  corepack prepare pnpm@latest --activate
fi

# --- Claude Code ---

if ! command -v claude &>/dev/null; then
  log "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | sh
fi

# --- tmux plugins ---

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  log "Updating tmux plugins..."
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
else
  log "Installing tpm + plugins..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
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
