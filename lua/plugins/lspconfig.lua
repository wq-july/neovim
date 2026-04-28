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
      },
    },
  },
}
