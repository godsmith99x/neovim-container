-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "monekai",

	hl_override = {
		FloatBorder = { fg = "#96c367" },
	},
}

M.term = {
  float = {
    width = 0.85,
    height = 0.85,
    row = 0.02,
    col = 0.05,
    border = "single",
  },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  callback = function()
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#96c367" })
  end,
})

return M
