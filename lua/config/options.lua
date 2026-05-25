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

local function configure_osc52_clipboard()
  -- 在 SSH/tmux 里用 OSC52 把 yanks 写入本地终端剪贴板。
  -- 只在远程/复用器环境启用，避免影响 Neovide 或本机桌面剪贴板 provider。
  if not (vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.TMUX) then
    return
  end

  vim.g.clipboard = "osc52"
  vim.opt.clipboard = "unnamedplus"
end

configure_osc52_clipboard()

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = configure_osc52_clipboard,
})
