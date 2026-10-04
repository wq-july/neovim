local python_env = require("config.python_env")

-- SLAM is edited in WSL but compiled with ROS dependencies inside Docker.
-- Each source tree therefore gets a clangd client with an explicit, mounted
-- compile-database root. Other C/C++ projects keep their normal local clangd.
local slam_workspace = vim.fn.expand("~/Project/slam")
local slam_roots = {
  { name = "slam-vins", path = slam_workspace .. "/VINS" },
  { name = "slam-orb-slam2", path = slam_workspace .. "/ORB_SLAM/ORB_SLAM2" },
  { name = "slam-orb-slam3", path = slam_workspace .. "/ORB_SLAM/ORB_SLAM3" },
  { name = "slam-dm-vio", path = slam_workspace .. "/DM_VIO" },
}
local clangd_arguments = {
  "--background-index",
  "--clang-tidy=false",
  "--all-scopes-completion=false",
  "--completion-style=bundled",
  "--header-insertion=never",
  "--function-arg-placeholders=false",
  "--limit-results=80",
  "--pch-storage=memory",
  "--log=error",
  "-j=4",
}

local function has_prefix(path, prefix)
  return path == prefix or vim.startswith(path, prefix .. "/")
end

local function slam_root_for_file(file)
  for _, root in ipairs(slam_roots) do
    if has_prefix(file, root.path) then
      return root
    end
  end
end

local function clangd_root_dir(bufnr, on_dir)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    on_dir(vim.fn.getcwd())
    return
  end

  -- Prefer the generated compile database over a nested .git directory.  In
  -- particular, VINS-Mono lives inside the VINS catkin workspace.
  local database = vim.fs.find("compile_commands.json", {
    path = vim.fs.dirname(file),
    upward = true,
  })[1]
  local root = database and vim.fs.dirname(database)
    or vim.fs.root(file, { ".clangd", "CMakeLists.txt", ".git" })
  on_dir(root or vim.fs.dirname(file))
end

-- Each service has its own WSL library header copy. Reuse its active client
-- when navigating from project code into a library.
local function slam_root_for_header(file)
  for service, fallback in pairs({ vins = slam_roots[1], orbslam = slam_roots[2], ["dm-vio"] = slam_roots[4] }) do
    if has_prefix(file, slam_workspace .. "/.cache/headers/" .. service)
      or vim.startswith(file, slam_workspace .. "/.cache/headers/snapshots/" .. service .. "-") then
      for _, client in ipairs(vim.lsp.get_clients()) do
        for _, root in ipairs(slam_roots) do
          if client.name == root.name and (root == fallback or (service == "orbslam" and root == slam_roots[3])) then
            return root
          end
        end
      end
      return fallback
    end
  end
end

local function non_slam_clangd_root_dir(bufnr, on_dir)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if slam_root_for_file(file) or slam_root_for_header(file) then
    return
  end
  clangd_root_dir(bufnr, on_dir)
end

local function docker_clangd_command(root)
  local command = { slam_workspace .. "/scripts/dev/clangd", "--project-root", root.path }
  vim.list_extend(command, vim.deepcopy(clangd_arguments))
  return command
end

-- Do not rely on the terminal's current directory: Neovim may have been
-- started elsewhere. This client always uses the known, mounted source root.
local function start_slam_client(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local root = slam_root_for_file(file) or slam_root_for_header(file)
  if not root then
    return
  end
  vim.lsp.start({
    name = root.name,
    cmd = docker_clangd_command(root),
    cmd_cwd = root.path,
    root_dir = root.path,
    capabilities = require("blink.cmp").get_lsp_capabilities({ offsetEncoding = { "utf-16" } }, true),
  }, { bufnr = bufnr })
end
local slam_lsp_group = vim.api.nvim_create_augroup("SlamClangd", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = slam_lsp_group,
  pattern = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  callback = function(event)
    start_slam_client(event.buf)
  end,
})
-- Retry a custom vim.lsp.start client after manually starting its container.
vim.api.nvim_create_user_command("SlamLspStart", function()
  start_slam_client(vim.api.nvim_get_current_buf())
end, { desc = "Attach the current SLAM buffer after manually starting its container", force = true })

-- Keep the essential navigation keys available even when a LazyVim preset
-- does not install its own LspAttach mappings.
local lsp_navigation_group = vim.api.nvim_create_augroup("UserLspNavigation", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_navigation_group,
  callback = function(event)
    local options = { buffer = event.buf, silent = true }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", options, { desc = "LSP: definition" }))
    vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", options, { desc = "LSP: references" }))
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", options, { desc = "LSP: implementation" }))
    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", options, { desc = "LSP: hover" }))
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", options, { desc = "LSP: rename" }))
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", options, { desc = "LSP: code action" }))
  end,
})

local function diagnostic_virtual_line_format(diagnostic)
  local source = diagnostic.source and diagnostic.source ~= "" and ("[" .. diagnostic.source .. "] ") or ""
  local code = diagnostic.code and diagnostic.code ~= "" and (tostring(diagnostic.code) .. ": ") or ""
  return source .. code .. diagnostic.message
end

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
      inlay_hints = { enabled = true },
      diagnostics = {
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "if_many",
        },
        virtual_text = false,
        virtual_lines = {
          current_line = true,
          format = diagnostic_virtual_line_format,
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
                autoImportCompletions = false,
                typeCheckingMode = "basic",
              },
            },
          },
        },
        clangd = {
          cmd = vim.list_extend({ "clangd" }, vim.deepcopy(clangd_arguments)),
          root_dir = non_slam_clangd_root_dir,
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          init_options = {
            completeUnimported = false,
            clangdFileStatus = false,
          },
        },
      },
    },
  },
}
