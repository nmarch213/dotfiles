#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

echo "==> Installing dotfiles..."

# Xcode CLI tools
if ! xcode-select -p &>/dev/null; then
  echo "==> Installing Xcode CLI tools..."
  xcode-select --install
  echo "Re-run this script after Xcode CLI tools finish installing."
  exit 0
fi

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Brew bundle
echo "==> Installing packages..."
brew bundle --file="$DOTFILES/Brewfile"

# Stow all packages
echo "==> Stowing configs..."
cd "$DOTFILES"
for pkg in zsh git starship ghostty tmux nvim ssh; do
  stow -v --adopt "$pkg" 2>/dev/null || stow -v "$pkg"
done
# Reset any adopted changes back to repo versions
git checkout -- .

# Rust via rustup
if ! command -v rustup &>/dev/null; then
  echo "==> Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env" 2>/dev/null || true
rustup update stable

# nvm
if [ ! -d "$HOME/.nvm" ]; then
  echo "==> Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# pnpm
if ! command -v pnpm &>/dev/null; then
  echo "==> Installing pnpm..."
  corepack enable
  corepack prepare pnpm@latest --activate
fi

# tmux plugins
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "==> Installing tmux plugins..."
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
else
  echo "==> Installing tpm..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

# macOS defaults
echo "==> Applying macOS defaults..."
bash "$DOTFILES/macos.sh"

echo ""
echo "==> Done! Manual steps:"
echo "  - Install Wispr Flow from App Store"
echo "  - Sign into: Arc, Raycast, Spotify, Slack, etc."
echo "  - Copy SSH keys from secure backup (or generate new + add to GitHub)"
echo "  - Import Raycast settings"
echo "  - Restart terminal"
