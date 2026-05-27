return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.lua = { "stylua" }
      opts.formatters_by_ft.python = { "black" }
      opts.formatters_by_ft.sh = { "shfmt" }
      opts.formatters_by_ft.bash = { "shfmt" }
      opts.formatters_by_ft.zsh = { "shfmt" }
      opts.formatters_by_ft.markdown = { "prettier" }
      opts.formatters_by_ft["markdown.mdx"] = { "prettier" }
      opts.formatters_by_ft.json = { "prettier" }
      opts.formatters_by_ft.yaml = { "prettier" }
      opts.formatters_by_ft.yml = { "prettier" }
      opts.formatters_by_ft.html = { "prettier" }
      opts.formatters_by_ft.css = { "prettier" }
      opts.formatters_by_ft.javascript = { "prettier" }
      opts.formatters_by_ft.typescript = { "prettier" }

      opts.default_format_opts = vim.tbl_deep_extend("force", opts.default_format_opts or {}, {
        lsp_format = "fallback",
        timeout_ms = 3000,
      })


      opts.formatters = opts.formatters or {}
      opts.formatters.black = vim.tbl_deep_extend("force", opts.formatters.black or {}, {
        command = vim.fn.exepath("black") ~= "" and vim.fn.exepath("black") or "black",
        prepend_args = {
          "--line-length",
          "100",
        },
      })
      opts.formatters.prettier = vim.tbl_deep_extend("force", opts.formatters.prettier or {}, {
        command = vim.fn.exepath("prettier") ~= "" and vim.fn.exepath("prettier") or "prettier",
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
        desc = "Format buffer",
        mode = { "n", "v" },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("HermesConformFormatOnSave", { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
            return
          end
          if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
            return
          end
          if vim.api.nvim_buf_line_count(bufnr) > 3000 then
            return
          end
          local ok, conform = pcall(require, "conform")
          if not ok then
            return
          end
          conform.format({
            bufnr = bufnr,
            async = false,
            timeout_ms = 3000,
            lsp_format = "fallback",
          })
        end,
      })

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.autoformat = false
        else
          vim.g.autoformat = false
        end
      end, {
        bang = true,
        desc = "Disable autoformat-on-save globally, or for current buffer with !",
      })

      vim.api.nvim_create_user_command("FormatEnable", function(args)
        if args.bang then
          vim.b.autoformat = true
        else
          vim.g.autoformat = true
        end
      end, {
        bang = true,
        desc = "Enable autoformat-on-save globally, or for current buffer with !",
      })
    end,
  },
}
