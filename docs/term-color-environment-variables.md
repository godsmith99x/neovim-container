# The `TERM` and `COLORTERM` Environment Variables

The `-e TERM=xterm-256color` flag in the `podman run` command passes the `TERM` environment variable into the container. `TERM` tells terminal applications what kind of terminal they're running in, so they can use the correct escape codes for colors, cursor movement, bold, italics, etc.

Without it, `TERM` inside the container may be unset or default to something minimal (like `dumb`), causing Neovim, tmux, and other TUI apps to render incorrectly or refuse to show colors at all.

## Common Values

| Value | Colors | Notes |
|---|---|---|
| `dumb` | 0 | Absolute minimum. No escape codes. Many TUI apps refuse to run. |
| `vt100` | 0 | 1970s VT100. Basic cursor movement, no color. |
| `xterm` | 8 | Basic xterm — 8 foreground/background colors. |
| `xterm-256color` | 256 | Most common for modern terminal emulators. Neovim themes need this minimum. |
| `tmux-256color` | 256 | Like `xterm-256color` but with tmux-specific capabilities (e.g. italics). Useful *inside* tmux. |
| `screen-256color` | 256 | GNU Screen variant. Sometimes used inside tmux as a fallback. |
| `alacritty` | 256 | Alacritty-specific terminfo. Not universally available in containers. |
| `xterm-kitty` | 256+ | Kitty terminal. Supports extra features like the graphics protocol. Requires kitty's terminfo to be present in the container. |

## True Color (24-bit)

There is no standard `TERM` value for true color. Apps detect 24-bit color support via the separate `COLORTERM` variable instead. To enable it, keep `TERM=xterm-256color` and add:

```
-e COLORTERM=truecolor
```

## Recommendation

`xterm-256color` is the right choice for this setup. It is universally supported, always present in container base images, and gives Neovim everything it needs for themes and syntax highlighting.

If italics stop rendering correctly inside tmux, switch to `tmux-256color` — but that terminfo entry must exist in the container image.

---

# The `COLORTERM` Environment Variable

`TERM=xterm-256color` only advertises 256 colors — that is what the terminfo entry describes. It says nothing about true color support. `COLORTERM` is the separate, out-of-band signal that tells Neovim (and other TUI apps) the terminal actually supports 24-bit RGB escape codes.

Without it, Neovim will not enable true color even if the host terminal supports it, because `podman run` does not inherit the host environment — only explicitly passed `-e` flags reach the container. Colorschemes get degraded to the nearest 256-color approximation, which can look noticeably worse. This also means `vim.o.termguicolors = true` in your Neovim config will not take full effect.

## Possible Values

| Value | Meaning |
|---|---|
| `truecolor` | 24-bit RGB support. The standard value used by most modern terminals. |
| `24bit` | Older alias for the same thing. Less common, but accepted by some apps. |
| unset / anything else | Treated as no true color support. Apps fall back to 256 colors. |

## Why Not Pass Through `${COLORTERM}` from the Host?

Unlike `TERM`, there is no terminfo lookup involved — apps just check whether the value is `truecolor` or `24bit`. So passthrough is lower risk. However, if `nvim-container.sh` is called from a context where `$COLORTERM` is unset (e.g. a non-interactive script, an SSH session, or a minimal shell), Podman would receive `-e COLORTERM=` (empty string) and Neovim would silently downgrade to 256 colors with no error.

Hardcoding `-e COLORTERM=truecolor` is the safer and more explicit choice. This container is built specifically to run Neovim with a full config, so true color is always the right intent. There is no reason to ever want less.
