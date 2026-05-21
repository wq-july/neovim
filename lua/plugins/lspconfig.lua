local python_env = require("config.python_env")

local pyright_root_markers = {
  "pyrightconfig.json",
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  ".git",
}

local function pyright_root_dir(bufnr, on_dir)
  local root = vim.fs.root(bufnr, pyright_root_markers)
  local file = vim.api.nvim_buf_get_name(bufnr)

  -- Loose learning scripts often do not live in a project root. Falling back
  -- to the file directory keeps Pyright attached, so diagnostics update live.
  if not root and file ~= "" then
    root = vim.fs.dirname(file)
  end

  on_dir(root or vim.fn.getcwd())
end

return {
  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    ---@class PluginLspOpts
    opts = {
      diagnostics = {
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "if_many",
        },
        virtual_text = {
          spacing = 2,
          source = "if_many",
        },
      },
      ---@type lspconfig.options
      servers = {
        -- Python 只保留一个干净的 Pyright LSP；Ruff LSP/额外降噪规则先全部移除，后续再按需要逐项加回。
        pyright = {
          cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/pyright-langserver"), "--stdio" },
          root_dir = pyright_root_dir,
          before_init = function(_, config)
            local python = python_env.resolve_python(config.root_dir, vim.api.nvim_buf_get_name(0))
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = python
            config.settings.python.defaultInterpreterPath = python
          end,
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                typeCheckingMode = "basic",
              },
            },
          },
        },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--background-index-priority=background",
            "--clang-tidy=false",
            "--all-scopes-completion=false",
            "--completion-style=bundled",
            "--header-insertion=never",
            "--function-arg-placeholders=false",
            "--limit-results=80",
            "--limit-references=200",
            "--pch-storage=memory",
            "--malloc-trim",
            "--log=error",
            "-j=4",
          },
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          init_options = {
            completeUnimported = false,
            clangdFileStatus = false,
          },
        },
        -- sidekick.nvim 的 Next Edit Suggestions 依赖 Copilot LSP。
        -- 使用 Mason 安装后的绝对路径，避免 Neovim PATH 未包含 mason/bin 时找不到命令。
        copilot = {
          cmd = { "/home/wq/.local/share/nvim/mason/bin/copilot-language-server", "--stdio" },
        },
      },
    },
  },
}
