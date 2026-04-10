# Clipboard via OSC 52

## Setup

**Windows Terminal → SSH → RHEL8 VM (host tmux) → Podman container → Neovim**

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
vim.o.clipboard = 'unnamedplus'
```

### `entrypoint.sh`

Neovim must be launched **directly** (not wrapped in a tmux session inside the container). Running container tmux creates a new pty, which breaks the clipboard chain because the pty that Neovim's TUI channel writes to is no longer the SSH pty that Windows Terminal is listening on.

## Why tmux inside the container does not work

The host tmux is version 2.7 (RHEL8 package). DCS passthrough (`allow-passthrough`) was added in tmux 3.3a. If Neovim runs inside container tmux, the bare OSC 52 emitted through container tmux's pty reaches host tmux, which intercepts and drops it because it cannot re-emit it outward without a working `Ms` capability on its own outer terminal.
