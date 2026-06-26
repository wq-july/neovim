return {
  {
    "folke/which-key.nvim",
    opts = {
      -- 降低按 <Space> leader 后的等待感；保留 which-key 提示，但更快出现。
      delay = 100,
      plugins = {
        -- Remote clipboard providers can make getreg("+") / getreg("*") error.
        -- Keep normal register usage on `"`, but do not let which-key preview them.
        registers = false,
      },
    },
  },
}
