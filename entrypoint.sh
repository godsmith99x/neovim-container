#!/bin/bash

# Start a new tmux session running nvim with any arguments passed to this script; 
# when nvim exits, drop back to bash inside tmux
exec tmux new-session "nvim $(printf '%q ' "$@"); exec bash"