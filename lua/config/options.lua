-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 降低 <Space> leader 组合键的等待感。LazyVim 默认通常是 300ms；这里保持可用性但更跟手。
vim.opt.timeoutlen = 200
vim.opt.ttimeoutlen = 30

-- Keep format-on-save disabled by default. Use <leader>mf for manual formatting,
-- or :FormatEnable when automatic formatting is explicitly needed.
vim.g.autoformat = false

-- Neovim 0.11+ 的统一浮窗边框：补全、hover、signature、诊断等未单独配置的窗口都走圆角。
pcall(function()
  vim.o.winborder = "rounded"
end)

-- Keep popups opaque; rounded borders are configured separately.
vim.opt.winblend = 0
vim.opt.pumblend = 0

-- Let Noice own the command line UI. Keeping this global avoids depending on
-- whether remote GUI clients expose vim.g.neovide/NVIM_GUI inside the server.
vim.opt.cmdheight = 0
vim.opt.showcmd = false

-- Windows Neovide -> SSH remote Nvim: keep the bottom UI compact.
-- Without this, the global lualine/statusline can appear to float above one or
-- two empty rows caused by the command area and/or GUI padding.
local function is_neovide_gui()
  return vim.g.neovide or vim.env.NVIM_GUI == "neovide"
end

if is_neovide_gui() then
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_left = 0
  vim.g.neovide_padding_right = 0
  vim.opt.linespace = 0
end

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

vim.opt.colorcolumn = "100"
