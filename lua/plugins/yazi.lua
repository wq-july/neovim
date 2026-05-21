return {
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>yy",
        "<cmd>Yazi<cr>",
        mode = { "n", "v" },
        desc = "[Yazi] Open at current file",
      },
      {
        "<leader>yc",
        "<cmd>Yazi cwd<cr>",
        desc = "[Yazi] Open at Neovim cwd",
      },
      {
        "<leader>yr",
        "<cmd>Yazi toggle<cr>",
        desc = "[Yazi] Resume/toggle last session",
      },
    },
    ---@type YaziConfig | {}
    opts = {
      -- Keep netrw/LazyVim directory behavior unchanged for now; launch Yazi explicitly.
      open_for_directories = false,
      yazi_floating_window_border = "rounded",
      keymaps = {
        show_help = "<f1>",
        open_file_in_vertical_split = "<c-v>",
        open_file_in_horizontal_split = "<c-x>",
        open_file_in_tab = "<c-t>",
        send_to_quickfix_list = "<c-q>",
      },
      integrations = {
        -- This config uses snacks.nvim rather than telescope.nvim.
        grep_in_directory = "snacks.picker",
        grep_in_selected_files = "snacks.picker",
        picker_add_copy_relative_path_action = "snacks.picker",
      },
    },
  },
}
