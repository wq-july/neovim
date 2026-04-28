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
          settings = {
            python = {
              analysis = {
                -- 降低 pandas 等库的类型推断误报（如 TextFileReader.iloc）
                diagnosticSeverityOverrides = {
                  reportAttributeAccessIssue = "warning", -- 从 error 降为 warning，减少误报
                },
              },
            },
          },
        },
        clangd = {},
        -- sidekick.nvim 的 Next Edit Suggestions 依赖 Copilot LSP。
        -- 使用 Mason 安装后的绝对路径，避免 Neovim PATH 未包含 mason/bin 时找不到命令。
        copilot = {
          cmd = { "/home/wq/.local/share/nvim/mason/bin/copilot-language-server", "--stdio" },
        },
      },
    },
  },
}
