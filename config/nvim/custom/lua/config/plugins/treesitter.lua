-- =============================================================================
-- plugins/treesitter.lua
-- Configuration for nvim-treesitter.
--
-- Neovim 0.12 bundles parsers for: c, lua, vim, markdown, markdown_inline,
-- vimdoc, query. The parsers listed below are NOT bundled and will be
-- compiled on first launch. Compilation requires gcc + make (both installed
-- in the container image). Compiled parsers are stored in
-- ~/.local/share/nvim/parser/ which is on the host-mounted volume
-- (~/.local/share/nvim-cont on the host), so they survive image rebuilds.
--
-- Notes:
--   - "ansible" has no dedicated grammar; Ansible files are YAML — covered
--     by the "yaml" parser.
--   - "terraform" uses the "hcl" grammar (HashiCorp Configuration Language).
--   - "c" is already bundled with Neovim 0.12 but listed here so treesitter
--     highlight is explicitly enabled for it.
-- =============================================================================

local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if ok then
  treesitter.setup({
    ensure_installed = {
      "bash",
      "c",
      "dockerfile",
      "go",
      "hcl",         -- Terraform
      "javascript",
      "json",
      "python",
      "rust",
      "typescript",
      "yaml",
    },
    auto_install = false,  -- only install what's in ensure_installed
    highlight = {
      enable = true,
    },
  })
end
