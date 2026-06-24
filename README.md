# Dotfiles

Personal macOS dev configuration managed with Git, Homebrew Bundle, and GNU Stow.

## Dev Setup

Use this on an existing machine when you only want the development environment:

```sh
git clone git@github.com:nmarch213/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install-dev.sh
```

The dev installer uses `Brewfile.dev`, runs Homebrew with `--no-upgrade`, installs the Codex, Claude Code, and opencode CLIs when missing, restows only dev config packages, installs tmux plugins with TPM, and refuses Stow conflicts instead of adopting existing files.

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

## Full Setup

Use this only for a full machine bootstrap:

```sh
cd ~/.dotfiles
./install.sh
```

The full installer applies all packages, app casks, language runtimes, tmux plugins, and macOS defaults. It is more invasive than the dev installer.

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
./install-dev.sh
```
