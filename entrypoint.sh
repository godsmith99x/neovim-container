#!/bin/bash

# Start nvim with any arguments passed to this script;
# when nvim exits, drop back to bash
nvim "$@"
exec bash