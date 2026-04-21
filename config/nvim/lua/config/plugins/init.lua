-- =============================================================================
-- plugins/init.lua
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
--   All sources are declared here first, then per-plugin config files follow.
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

require("config.plugins.monokai")
require("config.plugins.treesitter")
