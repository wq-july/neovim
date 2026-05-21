-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional global keymaps here.

-- AI workflow keymaps live in lua/plugins/sidekick.lua.

-- Resize Neovim splits/panels with Ctrl + arrow keys.
-- Useful in Neovide where AI/terminal panels are normal splits.
local resize_opts = { silent = true }
local Terminal = require("config.terminal")

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

vim.keymap.set({ "n", "t" }, "<C-/>", function()
  Terminal.toggle_bottom(LazyVim.root())
end, { silent = true, desc = "Bottom Terminal (Root Dir)" })
vim.keymap.set({ "n", "t" }, "<C-_>", function()
  Terminal.toggle_bottom(LazyVim.root())
end, { silent = true, desc = "Bottom Terminal (Root Dir)" })
vim.keymap.set("n", "<leader>ft", function()
  Terminal.toggle_bottom(LazyVim.root())
end, { silent = true, desc = "Bottom Terminal (Root Dir)" })
vim.keymap.set("n", "<leader>fT", function()
  Terminal.toggle_bottom((vim.uv or vim.loop).cwd())
end, { silent = true, desc = "Bottom Terminal (cwd)" })

vim.keymap.set("n", "<leader>tr", function()
  Terminal.open_right(LazyVim.root())
end, { silent = true, desc = "Move terminal to right" })
vim.keymap.set("n", "<leader>td", function()
  Terminal.open_bottom(LazyVim.root())
end, { silent = true, desc = "Move terminal to bottom" })
vim.keymap.set("n", "<leader>tt", function()
  Terminal.toggle_layout(LazyVim.root())
end, { silent = true, desc = "Toggle terminal right/bottom" })

-- tmux 里 Ctrl+方向键通常不稳定，补一组可靠的备用键来调终端 panel 尺寸。
-- 注意：不要在 Insert/Terminal 模式绑定 <leader> 开头的按键。
-- <leader> 是空格；一旦 Insert/Terminal 存在 <Space> 前缀映射，普通空格输入会等待 timeoutlen，造成明显延迟。
vim.keymap.set("n", "<leader>t-", function()
  Terminal.resize(-4)
end, { silent = true, desc = "Shrink terminal panel" })
vim.keymap.set("n", "<leader>t=", function()
  Terminal.resize(4)
end, { silent = true, desc = "Grow terminal panel" })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_snacks_terminal_keymaps", { clear = true }),
  pattern = "snacks_terminal",
  callback = function(args)
    vim.keymap.set("t", "<C-l>", function()
      local job = vim.b[args.buf].terminal_job_id
      if job then
        vim.api.nvim_chan_send(job, "\12")
      end
    end, { buffer = args.buf, silent = true, desc = "Clear terminal" })
  end,
})

vim.api.nvim_create_user_command("TermRight", function()
  Terminal.open_right(LazyVim.root())
end, { desc = "Move terminal to right" })
vim.api.nvim_create_user_command("TermBottom", function()
  Terminal.open_bottom(LazyVim.root())
end, { desc = "Move terminal to bottom" })
vim.api.nvim_create_user_command("TermToggleLayout", function()
  Terminal.toggle_layout(LazyVim.root())
end, { desc = "Toggle terminal right/bottom" })
