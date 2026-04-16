-- =============================================================================
-- init.lua
-- Leader keys must be set before anything else loads.
-- =============================================================================

vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

require("config.plugins")  -- must come first: installs plugins before anything requires them
require("config.options")
require("config.keymaps")
require("config.clipboard")