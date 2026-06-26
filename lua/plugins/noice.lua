local function open_noice_cmdline()
  vim.opt.cmdheight = 0
  vim.opt.showcmd = false

  pcall(function()
    require("lazy").load({ plugins = { "noice.nvim" } })
  end)
  pcall(function()
    require("noice").enable()
  end)

  vim.schedule(function()
    local colon = vim.api.nvim_replace_termcodes(":", true, false, true)
    vim.api.nvim_feedkeys(colon, "n", false)
  end)
end

return {
  {
    "folke/noice.nvim",
    lazy = false,
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      cmdline = {
        enabled = true,
        view = "cmdline_popup",
      },
      views = {
        cmdline_popup = {
          position = {
            row = "25%",
            col = "50%",
          },
          win_options = {
            winblend = 0,
          },
        },
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
    keys = {
      {
        ":",
        open_noice_cmdline,
        mode = "n",
        desc = "Noice: command line",
      },
    },
  },
}
