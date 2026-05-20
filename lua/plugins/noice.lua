return {
  {
    "folke/noice.nvim",
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
            winblend = 22,
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
              winblend = 22,
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
              winblend = 22,
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
              winblend = 22,
            },
          },
        },
      },
    },
  },
}
