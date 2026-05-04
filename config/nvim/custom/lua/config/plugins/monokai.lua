-- =============================================================================
-- plugins/monokai.lua
-- Configuration for monokai-pro.nvim colorscheme.
-- =============================================================================

require("monokai-pro").setup({
  filter = "pro",           -- the "pro" filter: dark background, muted tones

  transparent_background = false,
  terminal_colors        = false, -- don't recolor terminal buffers (keeps lazygit looking like it does outside neovim)

  -- Italic styles — these mirror the original Monokai Pro VS Code theme.
  -- Set any to `{}` (empty table) if you don't want italics for that group.
  styles = {
    comment      = { italic = true },
    keyword      = { italic = true },
    type         = { italic = true },
    parameter    = { italic = true },
    annotation   = { italic = true },
  },

  inc_search = "background", -- how incremental search is highlighted:
                              -- "background" (filled) or "underline"
})

-- Apply the colorscheme.
-- vim.cmd.colorscheme() is the Lua-idiomatic way to call :colorscheme.
vim.cmd.colorscheme("monokai-pro-classic")
