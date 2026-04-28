return {
  -- Seamless keyboard navigation between Neovim splits and tmux panes.
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", desc = "Navigate left pane" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", desc = "Navigate down pane" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", desc = "Navigate up pane" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", desc = "Navigate right pane" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "Navigate previous pane" },
    },
  },

  -- Review AI-generated or agent-generated multi-file edits before accepting them.
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewToggleFiles",
      "DiffviewRefresh",
    },
  },
}
