#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
NVM_VERSION="${NVM_VERSION:-v0.40.5}"
# shellcheck disable=SC2034
DEV_PACKAGES=(agents zsh git starship ghostty tmux nvim)
# shellcheck disable=SC2034
FULL_PACKAGES=(agents zsh git starship ghostty tmux nvim ssh fonts)
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

log() { echo "==> $1"; }
warn() { echo "WARN: $1" >&2; }

require_command() {
  local command_name="$1"
  local message="${2:-$command_name is required}"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$message" >&2
    exit 1
  fi
}

resolve_link_reference() {
  local link_path="$1"
  local reference="$2"
  local base_dir
  local reference_dir
  local reference_name

  if [[ "$reference" = /* ]]; then
    reference_dir="$(dirname "$reference")"
    reference_name="$(basename "$reference")"
  else
    base_dir="$(dirname "$link_path")"
    reference_dir="$base_dir/$(dirname "$reference")"
    reference_name="$(basename "$reference")"
  fi

  if [ -d "$reference_dir" ]; then
    printf '%s/%s\n' "$(cd "$reference_dir" && pwd -P)" "$reference_name"
  else
    printf '%s\n' "$reference"
  fi
}

symlink_points_to() {
  local link_path="$1"
  local desired_target="$2"
  local current_target

  current_target="$(readlink "$link_path")"
  if [ "$current_target" = "$desired_target" ]; then
    return 0
  fi

  [ "$(resolve_link_reference "$link_path" "$current_target")" = "$(resolve_link_reference "$link_path" "$desired_target")" ]
}

replace_with_symlink() {
  local link_target="$1"
  local link_path="$2"

  mkdir -p "$(dirname "$link_path")"

  if [ -L "$link_path" ]; then
    if symlink_points_to "$link_path" "$link_target"; then
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

ensure_xcode_cli_tools() {
  if ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode CLI tools..."
    xcode-select --install
    echo "Re-run this script after Xcode CLI tools finish installing."
    exit 0
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_stow_available() {
  require_command brew "Homebrew is required. Install it first, then rerun this script."

  if ! command -v stow >/dev/null 2>&1; then
    log "Installing Stow for conflict checks..."
    brew install stow
  fi
}

check_stow_conflicts() {
  local packages=("$@")

  require_command stow "GNU Stow is required."
  cd "$DOTFILES" || exit

  if ! stow -nvR "${packages[@]}"; then
    echo ""
    echo "Stow found conflicts. Back up or move the listed files, then rerun this script."
    echo "This script avoids --adopt so it does not overwrite existing machine-local config."
    exit 1
  fi
}

stow_packages() {
  local packages=("$@")

  require_command stow "GNU Stow is required."
  cd "$DOTFILES" || exit
  stow -vR "${packages[@]}"
}

install_brew_bundle() {
  local bundle_file="$1"
  shift

  if [ -f "$bundle_file" ]; then
    brew bundle --file="$bundle_file" "$@"
  fi
}

install_local_brew_bundles() {
  local flags=("$@")
  local host_bundle=""

  if command -v hostname >/dev/null 2>&1; then
    host_bundle="$DOTFILES/Brewfile.$(hostname -s).local"
  fi

  install_brew_bundle "$DOTFILES/Brewfile.local" "${flags[@]}"

  if [ -n "$host_bundle" ] && [ "$host_bundle" != "$DOTFILES/Brewfile.local" ]; then
    install_brew_bundle "$host_bundle" "${flags[@]}"
  fi
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

link_claude_agent_files() {
  log "Linking Claude agent files..."
  replace_with_symlink "../AGENTS.md" "$HOME/.claude/CLAUDE.md"
  replace_with_symlink "$DOTFILES/claude/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  ensure_claude_settings
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

install_agent_clis() {
  install_claude_code
  install_opencode
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

install_rust() {
  if ! command -v rustup >/dev/null 2>&1; then
    log "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  # shellcheck disable=SC1091
  source "$HOME/.cargo/env" 2>/dev/null || true
  rustup update stable
}

install_pnpm() {
  if ! command -v pnpm >/dev/null 2>&1; then
    log "Installing pnpm..."
    corepack enable
    corepack prepare pnpm@latest --activate
  fi
}

_doctor_passed=0
_doctor_failed=0
_doctor_warned=0

doctor_check() {
  local label="$1"
  shift

  if "$@" >/tmp/dotfiles-doctor.out 2>&1; then
    echo "[ok]   $label"
    _doctor_passed=$((_doctor_passed + 1))
  else
    echo "[fail] $label"
    sed 's/^/       /' /tmp/dotfiles-doctor.out
    _doctor_failed=$((_doctor_failed + 1))
  fi
}

doctor_warn() {
  local label="$1"
  shift

  if "$@" >/tmp/dotfiles-doctor.out 2>&1; then
    echo "[ok]   $label"
    _doctor_passed=$((_doctor_passed + 1))
  else
    echo "[warn] $label"
    sed 's/^/       /' /tmp/dotfiles-doctor.out
    _doctor_warned=$((_doctor_warned + 1))
  fi
}

doctor_skip_unless() {
  local command_name="$1"
  local label="$2"
  shift 2

  if command -v "$command_name" >/dev/null 2>&1; then
    doctor_check "$label" "$@"
  else
    echo "[skip] $label ($command_name not installed)"
  fi
}

check_managed_symlinks() {
  local paths=(
    "$HOME/AGENTS.md"
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.config/git"
    "$HOME/.config/starship.toml"
    "$HOME/.config/ghostty"
    "$HOME/.config/tmux"
    "$HOME/.config/nvim"
    "$HOME/.claude/CLAUDE.md"
    "$HOME/.claude/statusline-command.sh"
  )
  local failed=0
  local path

  for path in "${paths[@]}"; do
    if [ -L "$path" ] && [ ! -e "$path" ]; then
      echo "Broken symlink: $path -> $(readlink "$path")"
      failed=1
    fi
  done

  return "$failed"
}

check_packages_resolve() {
  brew bundle list --file="$DOTFILES/Brewfile.dev" >/dev/null
  brew bundle list --file="$DOTFILES/Brewfile" >/dev/null
}

describe_link_plan() {
  local label="$1"
  local target="$2"
  local path="$3"

  if [ -L "$path" ]; then
    if symlink_points_to "$path" "$target"; then
      echo "[ok]   $label already links to $target"
    else
      echo "[plan] $label symlink would be replaced: $path -> $target"
      echo "       current: $(readlink "$path")"
    fi
  elif [ -e "$path" ]; then
    echo "[plan] $label would back up existing path and create symlink: $path -> $target"
  else
    echo "[plan] $label would create symlink: $path -> $target"
  fi
}

describe_claude_settings_plan() {
  local settings="$HOME/.claude/settings.json"
  local default_settings="$DOTFILES/claude/.claude/settings.json"

  if [ ! -e "$settings" ]; then
    echo "[plan] Claude settings would be linked: $settings -> $default_settings"
    return
  fi

  if [ -L "$settings" ]; then
    case "$(readlink "$settings")" in
      "$default_settings" | "../.dotfiles/claude/.claude/settings.json")
        echo "[ok]   Claude settings already point at managed settings"
        ;;
      *)
        echo "[ok]   Claude settings is an existing symlink and would be preserved: $settings -> $(readlink "$settings")"
        ;;
    esac
    return
  fi

  if command -v jq >/dev/null 2>&1 && jq empty "$settings" >/dev/null 2>&1; then
    echo "[plan] Claude settings exists and is valid JSON; statusLine would be merged"
  else
    echo "[plan] Claude settings exists but is not valid JSON or jq is unavailable; installer would back it up and link managed settings"
  fi
}

describe_local_brew_bundle_plan() {
  local host_bundle=""

  if [ -f "$DOTFILES/Brewfile.local" ]; then
    echo "[plan] Local Brewfile overlay would run: $DOTFILES/Brewfile.local"
  fi

  if command -v hostname >/dev/null 2>&1; then
    host_bundle="$DOTFILES/Brewfile.$(hostname -s).local"
  fi

  if [ -n "$host_bundle" ] && [ -f "$host_bundle" ]; then
    echo "[plan] Host Brewfile overlay would run: $host_bundle"
  fi
}

run_dry_run() {
  local mode="${1:-dev}"
  local packages=()
  local brewfile=""
  local brew_flags=()

  case "$mode" in
    dev)
      packages=("${DEV_PACKAGES[@]}")
      brewfile="$DOTFILES/Brewfile.dev"
      brew_flags=(--no-upgrade)
      ;;
    full)
      packages=("${FULL_PACKAGES[@]}")
      brewfile="$DOTFILES/Brewfile"
      ;;
    *)
      echo "Usage: ./dot dry-run [dev|full]" >&2
      return 2
      ;;
  esac

  echo "Dotfiles dry run ($mode)"
  echo "Repo: $DOTFILES"
  echo "No filesystem or package changes will be made."
  echo ""

  echo "Packages:"
  printf '  %s\n' "${packages[@]}"
  echo ""

  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew manifest:"
    echo "[plan] brew bundle --file=$brewfile ${brew_flags[*]}"
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --file="$brewfile" >/dev/null
    echo "[ok]   $brewfile resolves"
    describe_local_brew_bundle_plan
  else
    echo "[warn] Homebrew is not installed; package manifest checks were skipped"
  fi
  echo ""

  if command -v stow >/dev/null 2>&1; then
    echo "Stow dry run:"
    (cd "$DOTFILES" && stow -nvR "${packages[@]}")
  else
    echo "[warn] GNU Stow is not installed; Stow conflict checks were skipped"
  fi
  echo ""

  echo "Claude links:"
  describe_link_plan "AGENTS.md" "../AGENTS.md" "$HOME/.claude/CLAUDE.md"
  describe_link_plan "Claude statusline" "$DOTFILES/claude/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  describe_claude_settings_plan
  echo ""

  echo "Other planned actions:"
  echo "[plan] Missing Claude Code and opencode CLIs would be installed"
  echo "[plan] nvm $NVM_VERSION and Node LTS would be installed or updated"
  echo "[plan] tmux plugins would be installed through TPM"

  if [ "$mode" = "full" ]; then
    echo "[plan] Rust stable would be installed or updated"
    echo "[plan] pnpm would be enabled through Corepack when missing"
    echo "[plan] macOS defaults from macos.sh would be applied"
  fi
}

run_doctor() {
  _doctor_passed=0
  _doctor_failed=0
  _doctor_warned=0

  echo "Dotfiles doctor"
  echo "Repo: $DOTFILES"
  echo ""

  doctor_check "macOS" test "$(uname -s)" = "Darwin"
  doctor_check "git available" command -v git
  doctor_check "Homebrew available" command -v brew
  doctor_check "Stow available" command -v stow
  doctor_check "jq available" command -v jq
  doctor_check "Brewfiles parse" check_packages_resolve
  doctor_check "installer shell syntax" bash -n "$DOTFILES/dot" "$DOTFILES/script/lib.sh" "$DOTFILES/install-dev.sh" "$DOTFILES/install.sh" "$DOTFILES/macos.sh" "$DOTFILES/claude/.claude/statusline-command.sh" "$DOTFILES/ghostty/.config/ghostty/tmux-launcher.sh"
  doctor_skip_unless shellcheck "shellcheck" shellcheck "$DOTFILES/dot" "$DOTFILES/script/lib.sh" "$DOTFILES/install-dev.sh" "$DOTFILES/install.sh" "$DOTFILES/macos.sh" "$DOTFILES/claude/.claude/statusline-command.sh" "$DOTFILES/ghostty/.config/ghostty/tmux-launcher.sh"
  doctor_check "zsh syntax" zsh -n "$DOTFILES/zsh/.zshrc"
  doctor_check "JSON config" jq empty "$DOTFILES/claude/.claude/settings.json" "$DOTFILES/nvim/.config/nvim/.neoconf.json" "$DOTFILES/nvim/.config/nvim/lazyvim.json" "$DOTFILES/nvim/.config/nvim/lazy-lock.json"
  doctor_check "Git config parses" git config --file "$DOTFILES/git/.gitconfig" --list
  doctor_check "SSH config parses" ssh -F "$DOTFILES/ssh/.ssh/config" -G github.com
  doctor_check "Stow dev dry run" bash -c "cd '$DOTFILES' && stow -nvR ${DEV_PACKAGES[*]}"
  doctor_check "Managed symlinks not broken" check_managed_symlinks
  doctor_skip_unless ghostty "Ghostty config validates" ghostty +validate-config --config-file="$DOTFILES/ghostty/.config/ghostty/config"
  doctor_skip_unless tmux "tmux config loads" tmux -L dotfiles-doctor -f "$DOTFILES/tmux/.config/tmux/tmux.conf" start-server \; source-file "$DOTFILES/tmux/.config/tmux/tmux.conf" \; kill-server
  doctor_skip_unless nvim "Neovim headless startup" nvim --headless "+lua print('nvim-ok')" +qa
  doctor_warn "GitHub CLI authenticated" gh auth status
  doctor_warn "Claude Code available" bash -c "command -v claude >/dev/null 2>&1 || [ -x '$HOME/.local/bin/claude' ]"
  doctor_warn "opencode available" bash -c "command -v opencode >/dev/null 2>&1 || [ -x '$HOME/.opencode/bin/opencode' ]"
  doctor_warn "tmux plugin manager installed" test -d "$HOME/.tmux/plugins/tpm"

  echo ""
  echo "Passed: $_doctor_passed  Warnings: $_doctor_warned  Failed: $_doctor_failed"

  [ "$_doctor_failed" -eq 0 ]
}
