#!/bin/bash

# Start a detached tmux session with a vertical split:
#   left pane  (66%): nvim; drops to bash when nvim exits
#   right pane (33%): opencode; drops to bash when opencode exits
NVIM_ARGS=$(printf '%q ' "$@")

exec tmux new-session -d -s main \; \
  send-keys "nvim ${NVIM_ARGS}; exec bash" Enter \; \
  split-window -h \; \
  send-keys "opencode; exec bash" Enter \; \
  resize-pane -t 0 -x "66%" \; \
  select-pane -t 0 \; \
  attach-session -t main