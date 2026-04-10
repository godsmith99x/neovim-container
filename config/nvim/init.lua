-- Clipboard via OSC 52 using Neovim's built-in TUI channel.
-- $TMUX is temporarily unset when copying so the built-in provider sends a
-- bare OSC 52 rather than a DCS passthrough sequence. The RHEL8 host tmux
-- (set-clipboard on + Ms terminfo override) intercepts the bare sequence and
-- forwards it to Windows Terminal, which sets the system clipboard.
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
  copy = {
    ['+'] = make_copy('+'),
    ['*'] = make_copy('*'),
  },
  paste = {
    ['+'] = osc52.paste('+'),
    ['*'] = osc52.paste('*'),
  },
}
vim.o.clipboard = 'unnamedplus'