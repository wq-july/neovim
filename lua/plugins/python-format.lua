return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_format", "ruff_organize_imports" }

      opts.formatters = opts.formatters or {}
      opts.formatters.ruff_format = vim.tbl_deep_extend("force", opts.formatters.ruff_format or {}, {
        command = vim.fn.expand("~/.local/share/nvim/mason/bin/ruff"),
      })
      opts.formatters.ruff_organize_imports = vim.tbl_deep_extend(
        "force",
        opts.formatters.ruff_organize_imports or {},
        {
          command = vim.fn.expand("~/.local/share/nvim/mason/bin/ruff"),
        }
      )
    end,
  },
}
