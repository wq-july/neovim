return{
  -- add any tools you want to have installed below
  {
    "mason-org/mason.nvim",
    init = function()
      local function prepend_path(path)
        path = vim.fn.expand(path)
        if vim.fn.isdirectory(path) == 1 and not vim.env.PATH:find(path, 1, true) then
          vim.env.PATH = path .. ":" .. vim.env.PATH
        end
      end

      -- Neovide/GUI Neovim may not inherit shell PATH. Keep developer tools available.
      prepend_path(vim.fn.stdpath("data") .. "/mason/bin")
      prepend_path("~/.npm-global/bin") -- prettier / markdownlint-cli2
      prepend_path("~/Installation/miniconda3/bin") -- ImageMagick: magick / identify / convert
      prepend_path("~/.local/bin")
    end,
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "clangd",
        "pyright",
        "prettier",
        -- black is provided by /usr/local/bin/black and configured in Conform;
        -- do not let Mason repeatedly try to install it during headless remote sessions.
      },
    },
  },
}
