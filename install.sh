#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=script/lib.sh
# shellcheck disable=SC1091
source "$DOTFILES/script/lib.sh"

ensure_xcode_cli_tools
ensure_homebrew
ensure_stow_available

log "Checking Stow conflicts..."
check_stow_conflicts "${FULL_PACKAGES[@]}"

log "Installing brew packages..."
install_brew_bundle "$DOTFILES/Brewfile"
# shellcheck disable=SC2119
install_local_brew_bundles

log "Stowing configs..."
stow_packages "${FULL_PACKAGES[@]}"

link_claude_agent_files

log "Installing Rust..."
install_rust

log "Installing Node LTS via nvm..."
install_nvm_and_node

install_pnpm

log "Installing missing agent CLIs..."
install_agent_clis

log "Installing tmux plugins..."
install_tmux_plugins

log "Applying macOS defaults..."
bash "$DOTFILES/macos.sh"

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
echo "  6. Open nvim - LazyVim will auto-install plugins on first launch"
