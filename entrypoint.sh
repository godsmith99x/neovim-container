#!/bin/bash
exec tmux new-session "nvim $(printf '%q ' "$@"); exec bash"