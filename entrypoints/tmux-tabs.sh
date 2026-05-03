#!/usr/bin/env bash

NVIM_ARGS=$(printf '%q ' "$@")

# Create neovim session with three named windows:
#   nvim-v    — Neovim (starts here)
#   opencode-k — opencode running in background
#   term-h     — shell ready for ad-hoc use
exec tmux new-session -d -s neovim -n nvim-v \;\
  send-keys "nvim ${NVIM_ARGS}; exec bash" Enter \;\
  new-window -t neovim -n opencode-k \;\
  send-keys "opencode; exec bash" Enter \;\
  new-window -t neovim -n term-h \;\
  select-window -t neovim:nvim-v \;\
  attach-session -t neovim
