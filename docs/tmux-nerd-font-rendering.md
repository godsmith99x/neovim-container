# Nerd Font Rendering Inside tmux

## Problem

Nerd Font icons rendered correctly in neovim without tmux, but appeared as underscores or boxes inside a tmux session. The characters copied correctly to the clipboard, confirming the codepoints were present but not being displayed properly.

## Root Cause

Four separate issues combined to cause the problem:

1. **No UTF-8 locale** — The container had `LANG` unset, defaulting to `POSIX`. tmux uses the C library's locale-aware functions (`wcwidth()`, `mbstowcs()`) to determine character widths and process multi-byte sequences. Without a UTF-8 locale, tmux cannot correctly interpret the 3-byte UTF-8 encoding of Nerd Font codepoints (which live in Unicode's Private Use Area, e.g. `U+E0B0` → `0xEE 0x82 0xB0`), and mangles them in its internal cell buffer.

2. **`default-terminal` set to `tmux-256color`** — Windows Terminal only activates Nerd Font glyph substitution for `xterm*` terminal types. With `TERM=tmux-256color` set inside the pane, Windows Terminal did not apply the fallback font for PUA codepoints.

3. **No true color passthrough** — Without a `terminal-overrides` entry, tmux intercepts 24-bit RGB escape sequences and downgrades them to 256 colors rather than forwarding them to Windows Terminal.

4. **Missing `tmux-256color` terminfo entry** — Ubuntu's default install does not include the `tmux-256color` terminfo entry, which caused neovim and other tools to fall back to basic rendering when querying terminal capabilities.

## Diagnosis Steps

```bash
# Confirm no UTF-8 locale in the container
locale

# Confirm the icon codepoint is present but not rendering correctly
printf '\xee\x82\xb0 Done\n'

# Confirm tmux has true color support from the outer terminal
tmux display -p '#{client_termfeatures}'

# Confirm neovim has termguicolors enabled
nvim --headless -c 'echo &termguicolors' -c 'qa!'

# Confirm the tmux-256color terminfo entry exists
infocmp tmux-256color
```

## Fix

### 1. Set UTF-8 locale in `nvim-container.sh`

Pass `LANG=C.UTF-8` to the container via `podman run`:

```bash
-e LANG=C.UTF-8 \
```

This is the most critical fix. Without it, tmux cannot process multi-byte UTF-8 sequences correctly regardless of other settings.

### 2. Configure tmux in `config/tmux/tmux.conf`

```
# Use xterm-256color so Windows Terminal applies Nerd Font substitution
set -g default-terminal "xterm-256color"
# Pass through true color (RGB) escape sequences to the outer terminal
set -ag terminal-overrides ",xterm-256color:RGB"
# Propagate COLORTERM so neovim knows true color is available
set-environment -g COLORTERM "truecolor"
```

### 3. Install `ncurses-term` in `Containerfile`

```dockerfile
apt-get install -y --no-install-recommends \
    ...
    ncurses-term
```

Provides the `tmux-256color` terminfo entry, used by neovim and other tools to correctly query terminal capabilities when `TERM=tmux-256color` is set outside of neovim (e.g. in the shell).
