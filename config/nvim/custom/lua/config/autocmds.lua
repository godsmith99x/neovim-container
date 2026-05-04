-- =============================================================================
-- autocmds.lua
-- Auto commands for enhanced editor behavior.
-- =============================================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Reload files when Neovim is idle (works in tmux where FocusGained doesn't fire)
augroup("AutoRead", { clear = true })
autocmd({ "CursorHold", "CursorHoldI" }, {
  group = "AutoRead",
  pattern = "*",
  command = "checktime",
})
