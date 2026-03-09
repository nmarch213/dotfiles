#!/bin/bash
# Auto-attach to existing tmux session or create a new one
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi
