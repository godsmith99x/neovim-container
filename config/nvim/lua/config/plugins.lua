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
