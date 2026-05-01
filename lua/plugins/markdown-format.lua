return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.markdown = { "prettier" }
      opts.formatters_by_ft["markdown.mdx"] = { "prettier" }

      opts.formatters = opts.formatters or {}
      opts.formatters.prettier = vim.tbl_deep_extend("force", opts.formatters.prettier or {}, {
        command = vim.fn.expand("~/.npm-global/bin/prettier"),
        prepend_args = {
          "--prose-wrap",
          "preserve",
          "--print-width",
          "100",
        },
      })
    end,
    keys = {
      {
        "<leader>mf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        desc = "[Markdown] Format with Prettier",
        mode = { "n", "v" },
      },
    },
  },
}
