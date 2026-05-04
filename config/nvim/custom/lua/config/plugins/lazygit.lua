-- =============================================================================
-- plugins/lazygit.lua
-- Configuration for lazygit.nvim.
-- Opens lazygit in a floating terminal window inside Neovim.
-- Requires the lazygit binary (installed in the container via Containerfile).
--
-- Keymaps:
--   <leader>g  — open lazygit (normal mode)
-- =============================================================================

-- lazygit.nvim has no setup() function — the :LazyGit command is available
-- automatically once the plugin is loaded.

vim.keymap.set("n", "<leader>g", "<cmd>LazyGit<cr>", {
  desc = "Open LazyGit",
  silent = true,
})

