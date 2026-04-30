#!/bin/bash

NVIM_ARGS=$(printf '%q ' "$@")

# Create neovim session with three named windows:
#   nvim      — Neovim (starts here)
#   opencode  — opencode running in background
#   terminal  — shell ready for ad-hoc use
exec tmux new-session -d -s neovim -n nvim \;\
  send-keys "nvim ${NVIM_ARGS}; exec bash" Enter \;\
  new-window -t neovim -n opencode \;\
  send-keys "opencode; exec bash" Enter \;\
  new-window -t neovim -n terminal \;\
  select-window -t neovim:nvim \;\
  attach-session -t neovim
