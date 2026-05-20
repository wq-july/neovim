-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 降低 <Space> leader 组合键的等待感。LazyVim 默认通常是 300ms；这里保持可用性但更跟手。
vim.opt.timeoutlen = 200
vim.opt.ttimeoutlen = 30

-- Neovim 0.11+ 的统一浮窗边框：补全、hover、signature、诊断等未单独配置的窗口都走圆角。
pcall(function()
  vim.o.winborder = "rounded"
end)
