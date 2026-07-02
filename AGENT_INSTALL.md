# Agent Install Runbook

Use this when an agent is going to install these dotfiles on another Mac.

## Safety Rules

- Prefer `./dot install-dev` for an existing machine.
- Use `./dot install-full` only on a fresh or intentionally managed machine.
- Do not run destructive commands such as `git reset --hard`, `rm -rf`, or `stow --adopt`.
- Do not move, overwrite, or delete user files unless the user explicitly approves the exact path.
- Stop on Stow conflicts. Report the conflicting paths and wait for direction.
- Keep a transcript of commands and important output.

## Phase 1: Fetch

```sh
git clone git@github.com:nmarch213/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git status -sb
git pull --ff-only
```

Expected state: clean worktree on `main`.

## Phase 2: Non-Mutating Preflight

Run the safe dry run first:

```sh
./dot dry-run dev
```

Use `./dot dry-run full` only when the user explicitly wants the full bootstrap.

Review the output for:

- Stow conflicts.
- Existing files that would be backed up.
- Missing Homebrew or Stow.
- Claude settings behavior.
- Local Brewfile overlays.

If there are Stow conflicts, stop and report them. Do not run the installer.

## Phase 3: Doctor

```sh
./dot doctor
```

Before install, warnings can be acceptable for tools that are not installed yet. Failures in shell syntax, JSON parsing, Git config, SSH config, or Stow dry-run are blockers.

## Phase 4: Install

Existing machine:

```sh
./dot install-dev 2>&1 | tee install-dev.log
```

Fresh or fully managed machine:

```sh
./dot install-full 2>&1 | tee install-full.log
```

Known side effects:

- Runs Homebrew Bundle.
- May run remote installers for Claude Code, opencode, nvm, Homebrew, rustup, and tmux TPM.
- Creates Stow-managed symlinks.
- Backs up replaced files with timestamped `*.backup.*` names.
- Updates or links Claude Code settings.
- Full install also applies `macos.sh`.

## Phase 5: Verify

```sh
./dot doctor
git status -sb
find "$HOME" -maxdepth 3 -name "*.backup.*" -print
```

Report:

- Whether `./dot doctor` passed.
- Any warnings that remain.
- Any backup files created.
- Any manual next steps, such as restarting the terminal or signing into apps.

## Stop Conditions

Stop and ask the user before continuing if:

- Stow reports conflicts.
- A command wants sudo unexpectedly.
- Homebrew, nvm, rustup, Claude, or opencode installers fail.
- The install would replace a file that looks user-authored and important.
- `./dot doctor` has failures after install.
