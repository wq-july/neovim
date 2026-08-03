return {
  {
    "kawre/leetcode.nvim",
    cmd = "Leet",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>ll", "<cmd>Leet<cr>", desc = "LeetCode dashboard" },
    },
    opts = {
      lang = "cpp",
      cn = {
        enabled = true,
        translator = true,
        translate_problems = true,
      },
      picker = { provider = "snacks-picker" },
      plugins = {
        -- Allow opening LeetCode without first closing your normal buffers.
        non_standalone = true,
      },
    },
  },
}
