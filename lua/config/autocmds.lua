-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Markdown 阅读降噪：保留公式/图片渲染，但关闭拼写检查带来的大量红色波浪线。
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_markdown_quiet", { clear = true }),
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.spell = false

    -- 如果波浪线来自诊断 underline，也一并隐藏；诊断 sign/virtual_text/浮窗仍保留。
    pcall(vim.diagnostic.config, {
      underline = false,
      signs = true,
      virtual_text = true,
      update_in_insert = false,
    })
  end,
})
