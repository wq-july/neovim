-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 降低 <Space> leader 组合键的等待感。LazyVim 默认通常是 300ms；这里保持可用性但更跟手。
vim.opt.timeoutlen = 200
vim.opt.ttimeoutlen = 30

-- LazyVim/Conform format-on-save switch. Keep enabled by default;
-- use :FormatDisable / :FormatEnable from lua/plugins/markdown-format.lua when needed.
vim.g.autoformat = true

-- Neovim 0.11+ 的统一浮窗边框：补全、hover、signature、诊断等未单独配置的窗口都走圆角。
pcall(function()
  vim.o.winborder = "rounded"
end)

-- Keep popups opaque; rounded borders are configured separately.
vim.opt.winblend = 0
vim.opt.pumblend = 0

local function configure_remote_clipboard()
  -- SSH/tmux remote editing defaults to Neovim internal registers.
  -- Use :Osc52Copy or <leader>cy when copying to the local system clipboard is needed.
  if not (vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.TMUX) then
    return
  end

  vim.g.clipboard = nil
  vim.opt.clipboard = ""
  vim.g.remote_osc52_manual_only = true
end

configure_remote_clipboard()

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = configure_remote_clipboard,
})
