return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- README/文档阅读体验优先：普通模式渲染，插入模式保持原文便于编辑。
      enabled = true,
      preset = "obsidian",
      render_modes = { "n", "c", "t" },
      completions = { lsp = { enabled = true } },
      heading = {
        sign = false,
        position = "overlay",
        icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
        width = "block",
        min_width = 80,
        border = true,
      },
      code = {
        sign = false,
        width = "block",
        min_width = 80,
        border = "thin",
        language_pad = 1,
      },
      bullet = {
        icons = { "•", "◦", "▪", "▫" },
      },
    },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "[Markdown] Toggle render" },
      { "<leader>mp", "<cmd>RenderMarkdown preview<cr>", desc = "[Markdown] Side preview" },
      { "<leader>mb", "<cmd>RenderMarkdown buf_toggle<cr>", desc = "[Markdown] Toggle buffer render" },
    },
  },
}
