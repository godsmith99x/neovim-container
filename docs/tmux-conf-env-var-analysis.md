# tmux.conf and Environment Variable Analysis

This document explains how the environment variables passed in the `podman run` command relate to the settings in `tmux.conf`, and the reasoning behind each line.

## Environment Variables in `podman run`

The three variables explicitly passed via `-e` flags are:

| Variable | Value |
|---|---|
| `TERM` | `xterm-256color` |
| `COLORTERM` | `truecolor` |
| `LANG` | `C.UTF-8` |

---

## Analysis of Each `tmux.conf` Setting

### `set -g default-terminal "tmux-256color"`

tmux sets `TERM` for processes running *inside* it to the value of `default-terminal`. So inside the container, tmux overrides the `TERM=xterm-256color` injected via `-e` and replaces it with `tmux-256color`. This is correct behavior — `tmux-256color` is the right `TERM` for processes running inside a tmux session.

The two work together: `TERM=xterm-256color` is what tmux itself sees when it starts (used to talk to the outer terminal / container PTY), and `default-terminal` controls the `TERM` value for the inner processes running in panes.

#### Dependency: `ncurses-term` in the Containerfile

Ubuntu's base `ncurses-base` package only ships a minimal set of terminfo entries. The `tmux-256color` terminfo entry is **not** included in `ncurses-base` — it lives in the `ncurses-term` package, which is why that package is installed in the `Containerfile`.

Without `ncurses-term`, when tmux starts inside the container and looks up the `tmux-256color` terminfo entry, it won't find it. tmux will either print an error like `open terminal failed: missing or unsuitable terminal: tmux-256color` or silently fall back, breaking color rendering and terminal capabilities for everything running in panes (including Neovim).

The full chain is:

1. `podman run -e TERM=xterm-256color` → tmux's outer terminal (`xterm-256color` terminfo is in `ncurses-base` ✓)
2. `set -g default-terminal "tmux-256color"` → inner terminal for panes (`tmux-256color` terminfo is in `ncurses-term` ✓)

If `default-terminal` were switched back to `xterm-256color`, `ncurses-term` would no longer be strictly required — but `tmux-256color` is the better value for panes, so both should be kept.

### `set -ag terminal-overrides ",xterm-256color:RGB"`

This tells tmux that the *outer* terminal (identified as `xterm-256color` via the injected `TERM`) supports true-color RGB sequences. Without this, tmux would strip RGB escape codes even though `COLORTERM=truecolor` is set. Required for 24-bit colors to pass through to the host terminal correctly.

### `set-environment -g COLORTERM "truecolor"`

`COLORTERM=truecolor` is already injected by `-e COLORTERM=truecolor` in the `podman run` command, and tmux propagates it into new windows and panes via its default `update-environment` list. This line is therefore redundant, but is kept as a belt-and-suspenders measure to guarantee the value is correct regardless of how the container shell started tmux.

### `set-environment -g LANG "C.UTF-8"`

`LANG=C.UTF-8` is injected by `-e LANG=C.UTF-8` and is also in tmux's default `update-environment` list, so it should propagate automatically. This line is kept as a belt-and-suspenders measure to guarantee correct locale (UTF-8) inside tmux panes, guarding against any context where `update-environment` propagation might not happen as expected (e.g. non-interactive shells, SSH sessions).

### `set -g allow-passthrough all`

Enables OSC/DCS escape sequence passthrough. This allows escape sequences (such as OSC 52 for clipboard integration, or the kitty image protocol) to pass through tmux directly to the host terminal without tmux intercepting them. Not directly related to the environment variables, but important for full terminal feature support.

`all` (tmux 3.3+ syntax) is required instead of `on`. `on` only covers DCS-wrapped sequences in visible panes; `all` covers bare OSC sequences and invisible/popup panes. Do not downgrade to `on`.

### `set -g mouse on`

Enables mouse support for scrolling, pane selection, and resizing. Unrelated to environment variables.

### `set-option -g history-limit 5000`

Sets the scrollback buffer to 5000 lines. Unrelated to environment variables.

### `setw -g mode-keys vi`

Uses vi keybindings in copy mode. Unrelated to environment variables.

### Alternate prefix and pane-switching bindings

```
set-option -g prefix2 M-z
bind-key M-z send-prefix -2
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
```

Convenience keybindings. Unrelated to environment variables.

---

## Summary Table

| `tmux.conf` line | Status | Reason |
|---|---|---|
| `set -g default-terminal "tmux-256color"` | Required | Correct `TERM` for processes inside tmux panes |
| `set -ag terminal-overrides ",xterm-256color:RGB"` | Required | Enables RGB passthrough to the outer terminal |
| `set-environment -g COLORTERM "truecolor"` | Belt-and-suspenders | Duplicate of `-e COLORTERM=truecolor`, but kept for safety |
| `set-environment -g LANG "C.UTF-8"` | Belt-and-suspenders | Duplicate of `-e LANG=C.UTF-8`, but kept for locale safety |
| `set -g allow-passthrough all` | Required | OSC/escape sequence passthrough to host terminal; `all` required for all pane types |
| `set -g mouse on` | Required | Mouse support |
| `set-option -g history-limit 5000` | Required | Scrollback buffer size |
| `setw -g mode-keys vi` | Required | Vi keybindings in copy mode |
| Prefix and pane-switching bindings | Required | Usability keybindings |
