-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local rounded_border = "rounded"

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = rounded_border,
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = rounded_border,
})

-- Python 学习脚本降噪：Pyright/Pylance 风格的 `"math" is not accessed` 属于 unused import 提示，
-- 对当前项目式学习干扰较大。这里在 LSP 发布诊断时直接过滤掉，比 severity override 更稳。
local default_publish_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
  local client = ctx and ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id) or nil
  if client and (client.name == "pyright" or client.name == "basedpyright") and result and result.diagnostics then
    result.diagnostics = vim.tbl_filter(function(diagnostic)
      local message = diagnostic.message or ""
      return not message:find("is not accessed", 1, true)
    end, result.diagnostics)
  end
  return default_publish_diagnostics(err, result, ctx, config)
end

-- 编码实时反馈：默认允许诊断在 Insert 模式下更新，这样不保存文件也能看到 LSP 问题。
-- Markdown/C++ 等特殊缓冲区可以在下面的局部配置里再单独降噪。
vim.diagnostic.config({
  update_in_insert = true,
  severity_sort = true,
  float = {
    border = rounded_border,
    source = "if_many",
  },
  virtual_text = {
    spacing = 2,
    source = "if_many",
  },
})

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
      virtual_text = {
        spacing = 2,
        source = "if_many",
      },
    }, args.buf)
  end,
})
