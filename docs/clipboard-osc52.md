# Clipboard via OSC 52

## Setup

**Windows Terminal → SSH → RHEL8 VM (host tmux) → Podman container (container tmux) → Neovim**

OSC 52 is a terminal escape sequence that lets applications set the system clipboard by writing to the terminal. Each layer in the chain must forward the sequence outward rather than absorbing it.

## Required configuration

### RHEL8 host `~/.tmux.conf`

```
set -g set-clipboard on
set -ag terminal-overrides ",xterm-256color:Ms=\\E]52;%p1%s;%p2%s\\007"
```

- `set-clipboard on` — when a pane application sends OSC 52, tmux intercepts it, stores it in the tmux buffer, and re-emits it outward to the outer terminal (Windows Terminal)
- `Ms` terminfo override — tells tmux that `xterm-256color` (what Windows Terminal advertises) accepts OSC 52 via that escape sequence; without this, tmux does not know where to forward the sequence

### `config/nvim/init.lua`

Neovim's built-in OSC 52 provider detects `$TMUX` and automatically wraps sequences in a DCS passthrough (`\033Ptmux;...\033\\`). RHEL8 ships tmux 2.7, which does not support `allow-passthrough` and cannot unwrap DCS sequences — so they are silently dropped. The workaround is to temporarily unset `$TMUX` before calling the provider so it sends a bare OSC 52 instead.

```lua
local osc52 = require('vim.ui.clipboard.osc52')

local function make_copy(reg)
  local inner = osc52.copy(reg)
  return function(lines, regtype)
    local saved = vim.env.TMUX
    vim.env.TMUX = nil
    inner(lines, regtype)
    vim.env.TMUX = saved
  end
end

vim.g.clipboard = {
  name = 'OSC 52',
  copy  = { ['+'] = make_copy('+'), ['*'] = make_copy('*') },
  paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
}
```

We intentionally do **not** set `vim.o.clipboard = 'unnamedplus'`. With that option, every text deletion (including single-character backspaces, `x`, `dw`, etc.) gets copied to the system clipboard, overwriting whatever you had there. The OSC 52 handlers on `vim.g.clipboard` are invoked only for explicit yank/paste operations via the `+` and `*` registers.

### `config/tmux/tmux.conf` (container)

```
set -g set-clipboard on
set -ag terminal-overrides ",xterm-256color:Ms=\\E]52;%p1%s;%p2%s\\007"
```

Same principle as the host tmux config: `set-clipboard on` intercepts bare OSC 52 from Neovim and re-emits it outward to the RHEL8 host tmux, which in turn forwards it to Windows Terminal.

## How it works end-to-end

1. Neovim calls `make_copy`, which temporarily unsets `$TMUX` and invokes the built-in OSC 52 provider
2. The provider sends a **bare** OSC 52 (no DCS wrapping) via Neovim's internal TUI channel
3. Container tmux intercepts it (`set-clipboard on` + `Ms`) and re-emits it outward
4. RHEL8 host tmux intercepts it (`set-clipboard on` + `Ms`) and re-emits it outward
5. Windows Terminal receives it and sets the system clipboard

## Why `$TMUX` must be unset before copying

Neovim's built-in OSC 52 provider detects `$TMUX` and automatically wraps sequences in a DCS passthrough (`\033Ptmux;...\033\\`). RHEL8 ships tmux 2.7, which does not support `allow-passthrough` (added in 3.3a) and cannot unwrap DCS sequences — so they are silently dropped. Temporarily unsetting `$TMUX` forces the provider to send a bare OSC 52 that both tmux layers can forward correctly.

## Copying from opencode and shell terminals

Opencode and the shell terminal run as **regular tmux windows** within the `neovim` session (not as popups). Because there is no `display-popup` boundary, tmux's clipboard forwarding (`set-clipboard on` + `Ms` terminfo override) works identically to any normal pane. OSC 52 sequences emitted by Neovim or captured by tmux copy-mode are forwarded outward through the container tmux → host tmux → Windows Terminal chain without interruption.

**Historical note:** The original design used `display-popup` windows to show opencode and the terminal as overlaid boxes. That approach was abandoned because tmux (as of 3.6a) does not forward OSC 52 through `display-popup` boundaries — confirmed by the tmux maintainer in issue #3817. Switching to regular tmux windows eliminated the problem entirely.
