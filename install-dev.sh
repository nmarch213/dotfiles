#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=script/lib.sh
# shellcheck disable=SC1091
source "$DOTFILES/script/lib.sh"

require_command brew "Homebrew is required. Install it first, then rerun this script."
ensure_stow_available

log "Checking Stow conflicts..."
check_stow_conflicts "${DEV_PACKAGES[@]}"

log "Installing missing dev packages without upgrading existing packages..."
install_brew_bundle "$DOTFILES/Brewfile.dev" --no-upgrade
install_local_brew_bundles --no-upgrade

log "Installing missing agent CLIs..."
install_agent_clis

log "Installing Node LTS via nvm..."
install_nvm_and_node

log "Stowing dev configs..."
stow_packages "${DEV_PACKAGES[@]}"

link_claude_agent_files

log "Installing tmux plugins..."
install_tmux_plugins

log "Done."
