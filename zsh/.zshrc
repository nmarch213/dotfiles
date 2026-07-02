# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Navigation
setopt AUTO_CD
setopt AUTO_PUSHD

# Completion (cached for speed)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# --- Plugins (load order matters) ---
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  BREW_PREFIX="$HOMEBREW_PREFIX"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_PREFIX="/usr/local"
else
  BREW_PREFIX="$(brew --prefix 2>/dev/null)"
fi

# fzf-tab (after compinit, before other plugins)
[[ -r "$BREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh" ]] && source "$BREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"

# Autosuggestions
[[ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Syntax highlighting (must be last plugin sourced)
[[ -r "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- fzf ---
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Use fd for fzf file search (respects .gitignore)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Catppuccin Mocha colors for fzf
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --height 40% --layout=reverse --border"

# fzf-tab config
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-flags --color=bg+:#313244,bg:#1e1e2e

# --- Tools ---
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Aliases
alias brainclaude="cd '$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain' && claude"
alias thots="open 'obsidian://open?path=$HOME/Developer/rival-labs/thoughts'"
alias yolo='claude --dangerously-skip-permissions'

alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'
alias find='fd'

# nvm (lazy-loaded)
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx pnpm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}
node() { unset -f nvm node npm npx pnpm; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
npm() { unset -f nvm node npm npx pnpm; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm "$@"; }
npx() { unset -f nvm node npm npx pnpm; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npx "$@"; }
pnpm() { unset -f nvm node npm npx pnpm; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; pnpm "$@"; }

# PATH
export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Machine-local shell overrides
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
