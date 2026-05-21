-- Sidekick.nvim - 统一 Neovim 内 AI CLI 与 Next Edit Suggestions
-- 设计原则：nvim 内直接打开/使用 AI sidekick；不再通过 tmux 快捷键启动 Codex。
local function prepend_path(path)
  if vim.fn.isdirectory(path) == 1 and not vim.env.PATH:find(path, 1, true) then
    vim.env.PATH = path .. ":" .. vim.env.PATH
  end
end

local function codex_cmd()
  -- Neovide 从桌面环境启动时通常拿不到 shell 初始化后的 PATH，导致 sidekick 认为 codex 未安装并打开 GitHub 页面。
  -- 这里显式补齐常见用户级 bin 路径，并优先固定到已安装的 codex CLI 绝对路径。
  prepend_path(vim.fn.expand("~/.npm-global/bin"))
  prepend_path(vim.fn.expand("~/.local/bin"))
  prepend_path(vim.fn.expand("~/.cargo/bin"))

  local candidates = {
    vim.fn.exepath("codex"),
    vim.fn.expand("~/.npm-global/bin/codex"),
    vim.fn.expand("~/.local/bin/codex"),
  }
  for _, cmd in ipairs(candidates) do
    if cmd ~= "" and vim.fn.executable(cmd) == 1 then
      return cmd
    end
  end
  return "codex"
end

local function codex_proxy_env()
  -- 保持和 ~/.zshrc 里的 proxy_on 默认值一致；Neovide 不会自动 source ~/.zshrc，所以这里单独给 Codex 进程注入代理。
  local proxy_addr = vim.env.CODEX_PROXY_ADDR or "127.0.0.1:10808"
  local http_proxy = "http://" .. proxy_addr
  local socks_proxy = "socks5://" .. proxy_addr
  local no_proxy = vim.env.NO_PROXY or vim.env.no_proxy or "localhost,127.0.0.1,::1,100.84.29.6,172.26.120.128"

  return {
    HTTP_PROXY = http_proxy,
    HTTPS_PROXY = http_proxy,
    ALL_PROXY = socks_proxy,
    http_proxy = http_proxy,
    https_proxy = http_proxy,
    all_proxy = socks_proxy,
    NO_PROXY = no_proxy,
    no_proxy = no_proxy,
  }
end

local function toggle_diffview()
  -- DiffviewOpen 本身不是 toggle；再次执行只会继续留在 diff tab。
  -- 用当前 tab 是否已有 diffview view 来决定关闭或打开，符合 <leader>ad 的“查看/退出 diff”习惯。
  local ok, lib = pcall(require, "diffview.lib")
  if ok and lib.get_current_view and lib.get_current_view() then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end

local function visual_selection_text()
  -- Sidekick 的 {selection} 依赖调用 send() 时仍处在 visual mode。
  -- <leader>as 会先打开 vim.ui.input，等用户输入后 visual mode 已经结束，
  -- 所以必须在弹输入框前主动捕获选区文本，避免后续出现 “Nothing to send”。
  local kind = require("sidekick.util").exit_visual_mode()
  if not kind then
    return nil
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
  local end_row, end_col = end_pos[2] - 1, end_pos[3]

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  local lines
  if kind == "line" then
    lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  elseif kind == "block" then
    lines = {}
    local from_col = math.min(start_col, end_col - 1)
    local to_col = math.max(start_col, end_col - 1)
    for row = start_row, end_row do
      local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
      lines[#lines + 1] = line:sub(from_col + 1, to_col + 1)
    end
  else
    lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
  end

  local text = table.concat(lines, "\n")
  vim.fn.feedkeys("gv", "nx") -- 保持/恢复可视选区，和 Sidekick 原生 selection 行为一致。
  return text:match("%S") and text or nil
end

local codex_layout = "bottom"

local function codex_split_opts(layout)
  return {
    width = layout == "right" and 0.40 or 0,
    height = layout == "bottom" and 0.30 or 0,
  }
end

local function set_codex_config_layout(layout)
  codex_layout = layout

  local win = require("sidekick.config").cli.win
  win.layout = layout
  win.split = vim.tbl_deep_extend("force", win.split or {}, codex_split_opts(layout))
  win.wo = vim.tbl_deep_extend("force", win.wo or {}, {
    winfixwidth = false,
    winfixheight = false,
  })
end

local function codex_states()
  return require("sidekick.cli.state").get({ name = "codex", attached = true })
end

local function current_codex_layout()
  for _, state in ipairs(codex_states()) do
    if state.terminal and state.terminal.opts and state.terminal.opts.layout then
      return state.terminal.opts.layout
    end
  end
  return codex_layout
end

local function apply_codex_layout(layout)
  set_codex_config_layout(layout)

  for _, state in ipairs(codex_states()) do
    local terminal = state.terminal
    if terminal then
      local was_open = terminal:is_open()
      local was_focused = was_open and terminal:is_focused()
      if was_open then
        terminal:hide()
      end

      terminal.opts.layout = layout
      terminal.opts.split = vim.tbl_deep_extend("force", terminal.opts.split or {}, codex_split_opts(layout))
      terminal.opts.wo = vim.tbl_deep_extend("force", terminal.opts.wo or {}, {
        winfixwidth = false,
        winfixheight = false,
      })

      if was_open then
        terminal:show()
        if was_focused then
          terminal:focus()
        end
      end
    end
  end
end

local function show_codex(layout, focus)
  layout = layout or codex_layout
  focus = focus ~= false
  apply_codex_layout(layout)

  local shown_existing = false
  for _, state in ipairs(codex_states()) do
    local terminal = state.terminal
    if terminal then
      if not terminal:is_open() then
        terminal:show()
      end
      if focus then
        terminal:focus()
      end
      shown_existing = true
    end
  end

  if not shown_existing then
    require("sidekick.cli").show({ name = "codex", focus = focus })
  end
end

local function toggle_codex()
  local has_open = false
  for _, state in ipairs(codex_states()) do
    if state.terminal and state.terminal:is_open() then
      state.terminal:hide()
      has_open = true
    end
  end
  if not has_open then
    show_codex(codex_layout, true)
  end
end

local function focus_or_blur_codex()
  for _, state in ipairs(codex_states()) do
    local terminal = state.terminal
    if terminal and terminal:is_open() then
      if terminal:is_focused() then
        terminal:blur()
      else
        terminal:focus()
      end
      return
    end
  end
  show_codex(codex_layout, true)
end

local function toggle_codex_layout()
  local layout = current_codex_layout()
  show_codex(layout == "right" and "bottom" or "right", true)
end

return {
  {
    "folke/sidekick.nvim",
    config = function(_, opts)
      require("sidekick").setup(opts)

      vim.api.nvim_create_user_command("CodexRight", function()
        show_codex("right", true)
      end, { desc = "Move Sidekick Codex CLI to the right" })
      vim.api.nvim_create_user_command("CodexBottom", function()
        show_codex("bottom", true)
      end, { desc = "Move Sidekick Codex CLI to the bottom" })
      vim.api.nvim_create_user_command("CodexToggleLayout", function()
        toggle_codex_layout()
      end, { desc = "Toggle Sidekick Codex CLI right/bottom" })
    end,
    opts = {
      nes = {
        enabled = true,
      },
      cli = {
        tools = {
          codex = {
            cmd = { codex_cmd() },
            env = codex_proxy_env(),
            -- 禁止 Neovide/PATH 异常时自动弹浏览器；如果真的找不到命令，只显示错误提示。
            url = false,
          },
        },
        -- 不使用 sidekick 的 tmux/zellij 持久化，保持 AI CLI 直接运行在 Neovim split 里。
        mux = {
          enabled = false,
          backend = "tmux",
        },
        win = {
          -- 把 Sidekick CLI 当成一个普通 nvim split 使用，和普通窗口一样用 Ctrl-h/j/k/l 进出。
          -- sidekick.nvim 默认会给 split 设置 winfixwidth/winfixheight；这里显式关闭，方便用 Ctrl-方向键调整 panel 大小。
          wo = {
            winfixwidth = false,
            winfixheight = false,
          },
          layout = "bottom",
          split = {
            width = 0.40,
            height = 0.30,
          },
          keys = {
            nav_left = { "<c-h>", "nav_left", expr = true, desc = "navigate to the left window" },
            nav_down = { "<c-j>", "nav_down", expr = true, desc = "navigate to the below window" },
            nav_up = { "<c-k>", "nav_up", expr = true, desc = "navigate to the above window" },
            nav_right = { "<c-l>", "nav_right", expr = true, desc = "navigate to the right window" },
          },
        },
      },
    },
    keys = {
      {
        "<c-.>",
        function()
          focus_or_blur_codex()
        end,
        mode = { "n", "t", "i", "x" },
        desc = "Sidekick: focus/blur Codex CLI",
      },
      {
        "<leader>ac",
        function()
          -- 不关闭/销毁 Codex 进程：如果窗口已打开就只隐藏窗口；如果已隐藏或未启动就显示/启动。
          -- 这样再次打开时可以复用仍在运行的 Codex session，避免重复启动导致卡顿。
          toggle_codex()
        end,
        mode = { "n", "x" },
        desc = "AI: show/hide Sidekick Codex CLI (keep process)",
      },
      {
        "<leader>ar",
        function()
          show_codex("right", true)
        end,
        mode = { "n", "x" },
        desc = "AI: move Sidekick Codex CLI to right",
      },
      {
        "<leader>ab",
        function()
          show_codex("bottom", true)
        end,
        mode = { "n", "x" },
        desc = "AI: move Sidekick Codex CLI to bottom",
      },
      {
        "<leader>al",
        function()
          toggle_codex_layout()
        end,
        mode = { "n", "x" },
        desc = "AI: toggle Sidekick Codex CLI right/bottom",
      },
      {
        "<leader>ad",
        toggle_diffview,
        mode = "n",
        desc = "AI: toggle diff review with Diffview",
      },
      {
        "<leader>as",
        function()
          local selection = visual_selection_text()
          if not selection then
            vim.notify("Sidekick: no visual selection to send", vim.log.levels.WARN)
            return
          end

          vim.ui.input({ prompt = "Sidekick instruction for selection: " }, function(input)
            if input and input:match("%S") then
              set_codex_config_layout(codex_layout)
              local text = require("sidekick.text").to_text(input .. "\n\n" .. selection)
              require("sidekick.cli").send({
                name = "codex",
                text = text,
                focus = true,
                submit = true,
              })
            end
          end)
        end,
        mode = "x",
        desc = "AI: ask Sidekick about selection",
      },
      {
        "<leader>ap",
        function()
          set_codex_config_layout(codex_layout)
          require("sidekick.cli").prompt({ name = "codex" })
        end,
        mode = { "n", "x" },
        desc = "AI: Sidekick prompt library",
      },
      {
        "<leader>af",
        function()
          set_codex_config_layout(codex_layout)
          require("sidekick.cli").send({ name = "codex", msg = "{file}", focus = true })
        end,
        mode = "n",
        desc = "AI: send file to Sidekick",
      },
      {
        "<leader>at",
        function()
          set_codex_config_layout(codex_layout)
          require("sidekick.cli").send({ name = "codex", msg = "{this}", focus = true })
        end,
        mode = { "n", "x" },
        desc = "AI: send current context to Sidekick",
      },
    },
  },
}
