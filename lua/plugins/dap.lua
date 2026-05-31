local function project_root()
  if LazyVim and LazyVim.root then
    return LazyVim.root()
  end
  return vim.fn.getcwd()
end

local function executable(path)
  return path and path ~= "" and vim.fn.executable(vim.fn.expand(path)) == 1
end

local function python_for_project()
  local ok, python_env = pcall(require, "config.python_env")
  if ok then
    local python = python_env.resolve_python(project_root(), vim.api.nvim_buf_get_name(0))
    if executable(python) then
      return vim.fn.expand(python)
    end
  end

  local python3 = vim.fn.exepath("python3")
  if executable(python3) then
    return python3
  end

  local python = vim.fn.exepath("python")
  if executable(python) then
    return python
  end

  return "python3"
end

local function has_debugpy(python)
  if not executable(python) then
    return false
  end
  vim.fn.system({ vim.fn.expand(python), "-c", "import debugpy" })
  return vim.v.shell_error == 0
end

local function python_for_debugpy()
  local project_python = python_for_project()
  if has_debugpy(project_python) then
    return project_python
  end

  for _, candidate in ipairs({ vim.fn.exepath("python3"), vim.fn.exepath("python") }) do
    if has_debugpy(candidate) then
      return candidate
    end
  end

  vim.notify(
    "debugpy is not available. Install it with: python -m pip install debugpy",
    vim.log.levels.ERROR
  )
  return project_python
end

local function split_args()
  local args = vim.fn.input("Args: ")
  if args == "" then
    return {}
  end
  return require("dap.utils").splitstr(args)
end

local function setup_project_launchjs_provider(dap)
  dap.providers.configs["user.project_launch_json"] = function()
    local launch_json = project_root() .. "/.config/launch.json"
    if vim.fn.filereadable(launch_json) ~= 1 then
      return {}
    end

    local ok, configs = pcall(require("dap.ext.vscode").getconfigs, launch_json)
    if not ok then
      vim.notify_once(
        "Unable to read .config/launch.json:\n" .. configs,
        vim.log.levels.WARN,
        { title = "DAP" }
      )
      return {}
    end

    return configs
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        opts = {},
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
          commented = true,
          virt_text_pos = "eol",
        },
      },
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Run/Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end, desc = "Stack Down" },
      { "<leader>dk", function() require("dap").up() end, desc = "Stack Up" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Debug UI" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Inspect Variable" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local dapui_ready = false

      local function ensure_dapui()
        if not dapui_ready then
          dapui.setup({})
          dapui_ready = true
        end
        return dapui
      end

      vim.schedule(function()
        ensure_dapui()
      end)

      vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticInfo", linehl = "Visual" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "R", texthl = "DiagnosticError" })

      dap.adapters.python = function(callback)
        callback({
          type = "executable",
          command = python_for_debugpy(),
          args = { "-m", "debugpy.adapter" },
        })
      end

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch current file",
          program = "${file}",
          cwd = project_root,
          python = python_for_project,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "python",
          request = "launch",
          name = "Launch current file with args",
          program = "${file}",
          args = split_args,
          cwd = project_root,
          python = python_for_project,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "python",
          request = "launch",
          name = "Launch module",
          module = function()
            return vim.fn.input("Module: ")
          end,
          args = split_args,
          cwd = project_root,
          python = python_for_project,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = "python",
          request = "attach",
          name = "Attach localhost:5678",
          connect = {
            host = "127.0.0.1",
            port = 5678,
          },
          cwd = project_root,
          python = python_for_project,
          justMyCode = false,
        },
      }

      setup_project_launchjs_provider(dap)

      dap.listeners.after.event_initialized["dapui_config"] = function()
        vim.schedule(function()
          ensure_dapui().open({})
        end)
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        vim.schedule(function()
          ensure_dapui().close({})
        end)
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        vim.schedule(function()
          ensure_dapui().close({})
        end)
      end

      vim.api.nvim_create_user_command("DapPythonInfo", function()
        vim.notify(
          ("Python: %s\nDebugpy adapter: %s"):format(python_for_project(), python_for_debugpy()),
          vim.log.levels.INFO
        )
      end, { desc = "Show Python debugger interpreter paths" })
    end,
  },
}
