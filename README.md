# Dotfiles

Personal macOS dev configuration managed with Git, Homebrew Bundle, and GNU Stow.

## Dev Setup

Use this on an existing machine when you only want the development environment:

```sh
git clone git@github.com:nmarch213/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./dot install-dev
```

The dev installer requires Homebrew, uses `Brewfile.dev` with `--no-upgrade`, installs the Codex, Claude Code, and opencode CLIs when missing, installs or updates nvm and Node LTS, restows only dev config packages, installs tmux plugins with TPM, and refuses Stow conflicts instead of adopting existing files.

Managed dev packages:

- `agents`
- `zsh`
- `git`
- `starship`
- `ghostty`
- `tmux`
- `nvim`

It also recreates:

- `~/AGENTS.md`
- `~/.claude/CLAUDE.md -> ../AGENTS.md`
- `~/.claude/statusline-command.sh`
- `~/.claude/settings.json` when missing, or just the `statusLine` field when a valid local settings file already exists

## CLI

Use `./dot` as the normal entrypoint:

```sh
./dot doctor
./dot dry-run
./dot install-dev
./dot install-full
./dot stow
./dot check-packages
./dot tmux-plugins
./dot macos
```

`doctor` runs syntax, Stow, package-manifest, shell, Git, SSH, Ghostty, tmux, Neovim, Claude, opencode, and TPM checks where the relevant tools are installed.

For an agent-run install, use [AGENT_INSTALL.md](AGENT_INSTALL.md).

## Full Setup

Use this only for a full machine bootstrap:

```sh
cd ~/.dotfiles
./dot install-full
```

The full installer applies all packages, app casks, language runtimes, tmux plugins, fonts, SSH config, and macOS defaults. It refuses Stow conflicts instead of adopting existing files, but it is still more invasive than the dev installer.

## Local Overrides

Machine-local files are intentionally ignored by Git:

- `~/.gitconfig.local` is included by the tracked Git config.
- `~/.zshrc.local` is sourced at the end of the tracked Zsh config.
- `Brewfile.local` and `Brewfile.<hostname>.local` can be placed in this repo for untracked local Homebrew packages.

## Side Effects

The installers run remote install scripts for Homebrew, Claude Code, opencode, nvm, and rustup when the relevant tools are missing. Existing files replaced by managed symlinks are backed up with a timestamp. The dev installer avoids Homebrew upgrades with `--no-upgrade`; the full installer is intended only for a fresh or intentionally managed machine.

## Updating

After changing live config files, commit from the dotfiles repo:

```sh
cd ~/.dotfiles
git status
git add agents zsh git starship ghostty tmux nvim claude
git commit -m "update dev config"
git push
```

On another machine:

```sh
cd ~/.dotfiles
git pull
./dot install-dev
```
