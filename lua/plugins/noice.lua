return {
  {
    "folke/noice.nvim",
    enabled = vim.env.NVIM_GUI ~= "neovide",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      views = {
        hover = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winblend = 0,
            winhighlight = {
              Normal = "NormalFloat",
              FloatBorder = "FloatBorder",
            },
          },
        },
      },
      lsp = {
        documentation = {
          opts = {
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winblend = 0,
              winhighlight = {
                Normal = "NormalFloat",
                FloatBorder = "FloatBorder",
              },
            },
          },
        },
        hover = {
          opts = {
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winblend = 0,
            },
          },
        },
        signature = {
          opts = {
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winblend = 0,
            },
          },
        },
      },
    },
  },
}
