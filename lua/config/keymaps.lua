-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional global keymaps here.

-- AI workflow keymaps live in lua/plugins/sidekick.lua.

-- Resize Neovim splits/panels. Avoid Ctrl+arrow because macOS often reserves it.
-- Alt+h/j/k/l works well over SSH when Option is sent as Meta; <leader>r* is a normal-mode fallback.
local resize_opts = { silent = true }
local Terminal = require("config.terminal")



-- Ctrl+Space 在部分 SSH/tmux/终端链路里会被编码成 <Nul>/<C-@>。
-- 用普通 Neovim keymap 直接吞掉这些按键，避免它们 fallback 成终端控制字符/屏幕残影。
local function manual_blink_completion_or_docs()
  local ok, cmp = pcall(require, "blink.cmp")
  if not ok then
    return
  end
  if cmp.is_documentation_visible and cmp.is_documentation_visible() then
    cmp.hide_documentation()
    return
  end
  if cmp.is_menu_visible and cmp.is_menu_visible() then
    cmp.show_documentation()
    return
  end
  cmp.show()
end

for _, lhs in ipairs({ "<C-Space>", "<C-@>", "<Nul>" }) do
  vim.keymap.set({ "i", "s" }, lhs, manual_blink_completion_or_docs, {
    silent = true,
    desc = "Blink: manual completion/docs without Ctrl-Space fallback",
  })
end

vim.keymap.set({ "n", "i", "t" }, "<M-h>", function()
  vim.cmd("vertical resize -4")
end, vim.tbl_extend("force", resize_opts, { desc = "Decrease window width" }))
vim.keymap.set({ "n", "i", "t" }, "<M-l>", function()
  vim.cmd("vertical resize +4")
end, vim.tbl_extend("force", resize_opts, { desc = "Increase window width" }))
vim.keymap.set({ "n", "i", "t" }, "<M-k>", function()
  vim.cmd("resize -2")
end, vim.tbl_extend("force", resize_opts, { desc = "Decrease window height" }))
vim.keymap.set({ "n", "i", "t" }, "<M-j>", function()
  vim.cmd("resize +2")
end, vim.tbl_extend("force", resize_opts, { desc = "Increase window height" }))

vim.keymap.set("n", "<leader>rh", function()
  vim.cmd("vertical resize -4")
end, vim.tbl_extend("force", resize_opts, { desc = "Decrease window width" }))
vim.keymap.set("n", "<leader>rl", function()
  vim.cmd("vertical resize +4")
end, vim.tbl_extend("force", resize_opts, { desc = "Increase window width" }))
vim.keymap.set("n", "<leader>rk", function()
  vim.cmd("resize -2")
end, vim.tbl_extend("force", resize_opts, { desc = "Decrease window height" }))
vim.keymap.set("n", "<leader>rj", function()
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


vim.keymap.set("i", "<C-l>", "<C-o>zz", {
  desc = "Center cursor line while inserting",
  silent = true,
})
