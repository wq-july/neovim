-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local rounded_border = "rounded"

local function diagnostic_virtual_line_format(diagnostic)
  local source = diagnostic.source and diagnostic.source ~= "" and ("[" .. diagnostic.source .. "] ") or ""
  local code = diagnostic.code and diagnostic.code ~= "" and (tostring(diagnostic.code) .. ": ") or ""
  return source .. code .. diagnostic.message
end

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = rounded_border,
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = rounded_border,
})

-- 干净的全局诊断显示：不再按 Pyright/Ruff 来源改写或过滤诊断。
vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = rounded_border,
    source = "if_many",
  },
  virtual_text = false,
  virtual_lines = {
    current_line = true,
    format = diagnostic_virtual_line_format,
  },
})

-- Markdown 阅读降噪：保留公式/图片渲染，但关闭拼写检查带来的大量红色波浪线。
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_markdown_quiet", { clear = true }),
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Python 项目环境自动对齐：
-- 1. 优先读取当前文件向上查找的 .nvim-python-env。
-- 2. 否则兼容 DeapLearning -> d2l_pytorch 的旧规则。
-- 3. 同步影响 :!python / :terminal / Python provider。
vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("user_project_python_env", { clear = true }),
  pattern = "*.py",
  callback = function(args)
    local file = vim.api.nvim_buf_get_name(args.buf)
    local python = require("config.python_env").resolve_python(vim.fs.root(file, { ".nvim-python-env", "pyproject.toml", ".git" }), file)
    require("config.python_env").apply_python(python)
  end,
})

vim.api.nvim_create_user_command("PythonEnvInfo", function()
  local lines = {
    "python3_host_prog = " .. tostring(vim.g.python3_host_prog),
    "CONDA_PREFIX = " .. tostring(vim.env.CONDA_PREFIX),
    "VIRTUAL_ENV = " .. tostring(vim.env.VIRTUAL_ENV),
    "python executable = " .. tostring(vim.fn.exepath("python")),
    "python3 executable = " .. tostring(vim.fn.exepath("python3")),
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Python Env" })
end, { desc = "Show Python interpreter used by Neovim" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_clangd_performance", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "clangd" then
      return
    end

    -- clangd semantic tokens and document highlights can dominate redraw cost in large C++ files.
    client.server_capabilities.semanticTokensProvider = nil
    client.server_capabilities.documentHighlightProvider = false

    vim.diagnostic.config({
      underline = false,
      update_in_insert = false,
      severity_sort = true,
      virtual_text = false,
      virtual_lines = {
        current_line = true,
        format = diagnostic_virtual_line_format,
      },
    }, args.buf)
  end,
})


-- Hermes: stable LSP refresh command ---------------------------------------------
local function restart_current_buffer_lsp()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients and vim.lsp.get_clients({ bufnr = bufnr }) or vim.lsp.get_active_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    client.stop(true)
  end
  vim.defer_fn(function()
    if vim.fn.exists(":LspStart") == 2 then
      vim.cmd("LspStart")
    else
      vim.cmd("edit")
    end
  end, 300)
end

vim.api.nvim_create_user_command("LspRefresh", restart_current_buffer_lsp, {
  desc = "Stop and restart LSP clients attached to the current buffer",
})

if vim.fn.exists(":LspRestart") == 0 then
  vim.api.nvim_create_user_command("LspRestart", restart_current_buffer_lsp, {
    desc = "Fallback LSP restart for current buffer",
  })
end
-- End Hermes LSP refresh command --------------------------------------------------
