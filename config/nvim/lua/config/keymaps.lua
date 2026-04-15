-- =============================================================================
-- keymaps.lua
-- General keybindings only. Plugin-specific bindings are added in each
-- plugin's own config file so it's always clear where a binding comes from.
-- =============================================================================

-- Shorthand: mode, lhs, rhs, description
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- ── Sanity ────────────────────────────────────────────────────────────────────

-- Clear search highlight with Escape (hlsearch=false means it clears on next
-- keypress anyway, but this makes it feel immediate and intentional)
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- ── File operations ───────────────────────────────────────────────────────────

map("n", "<leader>w",  "<cmd>write<CR>",  "Save file")
map("n", "<leader>W",  "<cmd>wall<CR>",   "Save all files")
map("n", "<leader>qq", "<cmd>qall<CR>",   "Quit all")

-- ── Window navigation ─────────────────────────────────────────────────────────
-- Ctrl+hjkl to move between splits instead of Ctrl+W then hjkl.
-- This is the single most used remap in any Vim config.

map("n", "<C-h>", "<C-w>h", "Move to left window")
map("n", "<C-j>", "<C-w>j", "Move to lower window")
map("n", "<C-k>", "<C-w>k", "Move to upper window")
map("n", "<C-l>", "<C-w>l", "Move to right window")

-- Resize splits with arrow keys (keeps hjkl free for navigation)
map("n", "<C-Up>",    "<cmd>resize +2<CR>",          "Increase window height")
map("n", "<C-Down>",  "<cmd>resize -2<CR>",          "Decrease window height")
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>", "Decrease window width")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Increase window width")

-- ── Buffer navigation ─────────────────────────────────────────────────────────

map("n", "<S-h>",      "<cmd>bprevious<CR>", "Previous buffer")
map("n", "<S-l>",      "<cmd>bnext<CR>",     "Next buffer")
map("n", "<leader>bd", "<cmd>bdelete<CR>",   "Delete buffer")

-- ── File explorer (netrw — built-in) ──────────────────────────────────────────
-- We're using the built-in netrw for now. No plugin needed.

map("n", "<leader>e", "<cmd>Explore<CR>", "Open file explorer")
map("n", "<leader>E", function()
  vim.cmd("aboveleft vsplit")
  vim.cmd("Explore")
  vim.cmd("vertical resize 30")
end, "Open explorer in left vertical split")

-- netrw hijacks <C-l> (refresh listing) and <C-h>, overriding window navigation.
-- Restore them as buffer-local mappings whenever a netrw buffer is opened.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    local opts = { buffer = true, silent = true }
    vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
    vim.keymap.set("n", "<C-l>", "<C-w>l", opts)
    vim.keymap.set("n", "<leader>r", "<cmd>e<CR>", opts)
  end,
})

-- ── Terminal ──────────────────────────────────────────────────────────────────

map("n", "<leader>tt", "<cmd>terminal<CR>", "Open terminal")
-- Escape from terminal mode back to normal mode with Esc Esc.
-- Single Esc is deliberately left alone — many terminal apps use it.
map("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")

-- ── Visual mode quality of life ───────────────────────────────────────────────

-- Stay in visual mode after indenting so you can indent repeatedly
map("v", "<", "<gv", "Dedent selection")
map("v", ">", ">gv", "Indent selection")

-- Move selected lines up/down with J/K (re-indents automatically with =)
map("v", "J", ":move '>+1<CR>gv=gv", "Move selection down")
map("v", "K", ":move '<-2<CR>gv=gv", "Move selection up")

-- ── Quickfix list ─────────────────────────────────────────────────────────────
-- The quickfix list is used by LSP (go to references, workspace diagnostics)
-- and by grep results. Worth learning even before LSP is set up.

map("n", "<leader>co", "<cmd>copen<CR>",  "Open quickfix list")
map("n", "<leader>cc", "<cmd>cclose<CR>", "Close quickfix list")
map("n", "]q",         "<cmd>cnext<CR>",  "Next quickfix item")
map("n", "[q",         "<cmd>cprev<CR>",  "Prev quickfix item")
