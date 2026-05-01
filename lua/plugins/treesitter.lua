return {
  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    auto_install = true,
    opts = {
      ensure_installed = {
        -- 基础
        "lua",
        "vim",
        "vimdoc",
        -- C / C++
        "c",
        "cpp",
        -- 脚本 / 配置
        "bash",
        "cmake",
        "python",
        "json",
        "yaml",
        -- Markdown / README 渲染依赖
        "markdown",
        "markdown_inline",
        "html",
      },
    },
    -- =========================
    -- 功能开关
    -- =========================
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },

    indent = {
      enable = true,
    },
    
    sync_install = false,

  },
}