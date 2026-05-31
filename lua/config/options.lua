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

local function configure_remote_clipboard()
  -- SSH/tmux 远程编辑时，默认用 OSC52 把 yanks 复制到本地系统剪贴板。
  if not (vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.TMUX) then
    return
  end

  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if not ok then
    return
  end

  vim.g.clipboard = {
    name = "OSC52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
    cache_enabled = 0,
  }
  vim.opt.clipboard = "unnamedplus"
  vim.g.remote_osc52_manual_only = false
end

configure_remote_clipboard()

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = configure_remote_clipboard,
})
