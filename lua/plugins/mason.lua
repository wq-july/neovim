return{
  -- add any tools you want to have installed below
  {
    "mason-org/mason.nvim",
    init = function()
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      if not vim.env.PATH:find(mason_bin, 1, true) then
        vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
      end
    end,
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "clangd",
        "copilot-language-server",
      },
    },
  },
}
