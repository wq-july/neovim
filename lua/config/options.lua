-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 降低 <Space> leader 组合键的等待感。LazyVim 默认通常是 300ms；这里保持可用性但更跟手。
vim.opt.timeoutlen = 200
vim.opt.ttimeoutlen = 30
