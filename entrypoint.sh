#!/bin/bash

NVIM_ARGS=$(printf '%q ' "$@")

# Create detached session for opencode that stays running in background
tmux new-session -d -s opencode-bg "opencode; exec bash"

# Create detached session for terminal popup that stays running in background
tmux new-session -d -s terminal-bg

# Create neovim session with neovim in a visible pane
exec tmux new-session -d -s neovim \;\
  send-keys "nvim ${NVIM_ARGS}; exec bash" Enter \;\
  attach-session -t neovim
