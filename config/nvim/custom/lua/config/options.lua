-- =============================================================================
-- options.lua
-- Core editor settings.
-- =============================================================================

local opt = vim.opt

-- ── UI ────────────────────────────────────────────────────────────────────────

opt.number         = true   -- show absolute line number on the current line
opt.signcolumn     = "yes"  -- always reserve space for signs (LSP, git) on the left;
                            -- prevents the text shifting when signs appear/disappear
opt.cursorline     = true   -- highlight the entire current line
opt.termguicolors  = true   -- enable 24-bit colour (required by most colorschemes)
opt.scrolloff      = 15      -- keep lines visible above/below the cursor at all times
opt.sidescrolloff  = 15      -- same for horizontal scrolling
opt.splitright     = true   -- vertical splits open to the right (Vim default is left)
opt.splitbelow     = true   -- horizontal splits open below (Vim default is above)
opt.showmode       = false  -- don't show "-- INSERT --"; the statusline will do this
opt.pumheight      = 12     -- limit the completion popup menu to 12 items tall

-- ── Editing ───────────────────────────────────────────────────────────────────

opt.wrap      = false   -- don't soft-wrap long lines (toggle with :set wrap if needed)
opt.linebreak = true    -- if wrap is toggled on, break at word boundaries not mid-word

opt.undofile = true     -- persist undo history to disk; survives closing and reopening
opt.swapfile = false    -- swap files are a crash-recovery mechanism made redundant by git
opt.backup   = false    -- same reasoning

opt.updatetime = 250    -- ms before CursorHold fires; controls LSP hover and git sign
                        -- responsiveness. Vim default is 4000ms which feels very sluggish.

opt.autoread = true    -- auto-reload files changed externally

-- ── Search ────────────────────────────────────────────────────────────────────

opt.ignorecase = true   -- case-insensitive search by default ...
opt.smartcase  = true   -- ... unless the query contains an uppercase letter
opt.hlsearch   = false  -- don't leave search highlights on screen after you're done

-- ── Indentation ───────────────────────────────────────────────────────────────
-- These are global defaults. Individual languages override them in autocmds.lua
-- (e.g. YAML gets 2 spaces, Make gets real tabs).

opt.expandtab   = true  -- pressing Tab inserts spaces, not a tab character
opt.shiftwidth  = 4     -- spaces per indent level (used by >>, <<, and auto-indent)
opt.tabstop     = 4     -- how wide a real tab character *appears*
opt.softtabstop = 4     -- how wide the Tab key *feels* in insert mode
opt.smartindent = true  -- auto-indent new lines intelligently based on context
