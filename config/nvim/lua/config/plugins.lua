-- =============================================================================
-- plugins.lua
-- Plugin declarations via vim.pack (built-in 0.12 plugin manager).
--
-- HOW IT WORKS:
--   vim.pack.add() clones plugins from GitHub into Neovim's data directory
--   (~/.local/share/nvim/pack/). A lockfile (nvim-pack-lock.json) is written
--   next to init.lua to pin versions.
--
-- WORKFLOW:
--   - First launch: plugins are installed automatically.
--   - To update: run :pack update  (shows a buffer listing available updates;
--     write the file with :w to confirm).
--   - To restart after changes: :restart  (0.12 built-in command)
--
-- IMPORTANT: vim.pack.add() must be called before require()-ing a plugin.
--   That's why this file is loaded first in init.lua.
-- =============================================================================

vim.pack.add({

  -- ── Colorscheme ─────────────────────────────────────────────────────────────
  -- Monokai Pro: six filter variants (pro, classic, octagon, machine,
  -- ristretto, spectrum). We use the "pro" filter.
  { src = "https://github.com/loctvl842/monokai-pro.nvim" },
  -- ── Colorscheme ─────────────────────────────────────────────────────────────

  -- ── Syntax highlighting ──────────────────────────────────────────────────────
  -- nvim-treesitter: parser management + highlight engine.
  -- Neovim 0.12 ships parsers for: c, lua, vim, markdown, markdown_inline,
  -- vimdoc, query. All others must be installed via nvim-treesitter.
  -- Parsers are compiled on first launch (requires gcc + make in the image)
  -- and persisted in the host-mounted ~/.local/share/nvim-cont volume.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  -- ── Syntax highlighting ──────────────────────────────────────────────────────

})

-- =============================================================================
-- Plugin configuration
-- Each plugin's setup() call lives here, directly below its declaration.
-- When we add more plugins later, their setup() calls will follow the same
-- pattern — declared in vim.pack.add() above, configured below.
-- =============================================================================

-- ── Monokai Pro ───────────────────────────────────────────────────────────────
require("monokai-pro").setup({
  filter = "pro",           -- the "pro" filter: dark background, muted tones

  transparent_background = false,
  terminal_colors        = true,  -- apply theme to the built-in :terminal too

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
-- ── Monokai Pro ───────────────────────────────────────────────────────────────

-- ── nvim-treesitter ───────────────────────────────────────────────────────────
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
local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if ok then
  treesitter.setup({
    ensure_installed = {
      "bash",
      "c",
      "dockerfile",
      "hcl",         -- Terraform
      "javascript",
      "json",
      "python",
      "typescript",
      "yaml",
    },
    auto_install = false,  -- only install what's in ensure_installed
    highlight = {
      enable = true,
    },
  })
end
-- ── nvim-treesitter ───────────────────────────────────────────────────────────
