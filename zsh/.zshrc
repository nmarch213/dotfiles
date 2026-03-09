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
BREW_PREFIX=$(brew --prefix)

# fzf-tab (after compinit, before other plugins)
source "$BREW_PREFIX/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"

# Autosuggestions
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Syntax highlighting (must be last plugin sourced)
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- fzf ---
source <(fzf --zsh)

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
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Aliases
alias brainclaude="cd '/Users/rival/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain' && claude"
alias thots="open 'obsidian://open?path=/Users/rival/Developer/rival-labs/thoughts'"
alias yolo='claude --dangerously-skip-permissions'

alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --paging=never'
alias find='fd'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PATH
export PATH="$HOME/.local/bin:$PATH"

# Auto-launch tmux in Ghostty
if [[ "$TERM_PROGRAM" == "ghostty" ]] && command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
  tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi
