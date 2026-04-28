-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional global keymaps here.

-- AI workflow keymaps live in lua/plugins/sidekick.lua.

-- Resize Neovim splits/panels with Ctrl + arrow keys.
-- Useful in Neovide where the Sidekick Codex panel is a normal right-side split.
local resize_opts = { silent = true }
vim.keymap.set({ "n", "i", "t" }, "<C-Left>", function()
  vim.cmd("vertical resize -4")
end, vim.tbl_extend("force", resize_opts, { desc = "Decrease window width" }))
vim.keymap.set({ "n", "i", "t" }, "<C-Right>", function()
  vim.cmd("vertical resize +4")
end, vim.tbl_extend("force", resize_opts, { desc = "Increase window width" }))
vim.keymap.set({ "n", "i", "t" }, "<C-Up>", function()
  vim.cmd("resize -2")
end, vim.tbl_extend("force", resize_opts, { desc = "Decrease window height" }))
vim.keymap.set({ "n", "i", "t" }, "<C-Down>", function()
  vim.cmd("resize +2")
end, vim.tbl_extend("force", resize_opts, { desc = "Increase window height" }))
