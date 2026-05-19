local python_env = require("config.python_env")

return {
  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {
          flags = {
            -- 编码时更快把未保存内容推给 LSP，配合 update_in_insert 实时显示问题。
            debounce_text_changes = 150,
          },
          before_init = function(_, config)
            local python = python_env.resolve_python(config.root_dir, vim.api.nvim_buf_get_name(0))
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = python
            config.settings.python.defaultInterpreterPath = python
          end,
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                -- 禁用 Pyright 的自动导入补全，避免接受补全时自动插入 _typeshed/Self 等奇怪 import。
                autoImportCompletions = false,
                -- 降低 pandas 等库的类型推断误报（如 TextFileReader.iloc）
                diagnosticSeverityOverrides = {
                  reportAttributeAccessIssue = "warning", -- 从 error 降为 warning，减少误报
                  -- 学习/实验脚本里经常会先 import 再逐步使用；这些不是环境错误，关闭提示避免干扰。
                  reportUnusedImport = "none",
                  reportUnusedVariable = "none",
                },
              },
            },
          },
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--background-index-priority=background",
            "--clang-tidy=false",
            "--all-scopes-completion=false",
            "--completion-style=bundled",
            "--header-insertion=never",
            "--function-arg-placeholders=false",
            "--limit-results=80",
            "--limit-references=200",
            "--pch-storage=memory",
            "--malloc-trim",
            "--log=error",
            "-j=4",
          },
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          init_options = {
            completeUnimported = false,
            clangdFileStatus = false,
          },
        },
        -- sidekick.nvim 的 Next Edit Suggestions 依赖 Copilot LSP。
        -- 使用 Mason 安装后的绝对路径，避免 Neovim PATH 未包含 mason/bin 时找不到命令。
        copilot = {
          cmd = { "/home/wq/.local/share/nvim/mason/bin/copilot-language-server", "--stdio" },
        },
      },
    },
  },
}
