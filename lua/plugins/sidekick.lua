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

local function hermes_cmd()
  prepend_path(vim.fn.expand("~/.local/bin"))
  prepend_path(vim.fn.expand("~/.cargo/bin"))

  local candidates = {
    vim.fn.exepath("hermes"),
    vim.fn.expand("~/.local/bin/hermes"),
  }
  for _, cmd in ipairs(candidates) do
    if cmd ~= "" and vim.fn.executable(cmd) == 1 then
      return cmd
    end
  end
  return "hermes"
end

local proxy_env_keys = {
  "HTTP_PROXY",
  "HTTPS_PROXY",
  "ALL_PROXY",
  "http_proxy",
  "https_proxy",
  "all_proxy",
}

local function read_file(path)
  path = vim.fn.expand(path)
  if vim.fn.filereadable(path) ~= 1 then
    return ""
  end
  return table.concat(vim.fn.readfile(path), "\n")
end

local function codex_uses_chatgpt_login()
  local override = (vim.env.CODEX_SIDEKICK_PROXY or ""):lower()
  if vim.tbl_contains({ "1", "true", "yes", "on" }, override) then
    return true
  end
  if vim.tbl_contains({ "0", "false", "no", "off" }, override) then
    return false
  end

  local config_text = read_file("~/.codex/config.toml")
  if config_text:find("ai%-route%-switcher: codex relay managed block", 1, false)
    or config_text:find('preferred_auth_method%s*=%s*"apikey"')
  then
    return false
  end

  local auth_text = read_file("~/.codex/auth.json")
  if auth_text == "" then
    return false
  end

  local ok, auth = pcall(vim.json.decode, auth_text)
  return ok and type(auth) == "table" and auth.auth_mode == "chatgpt"
end

local function clear_codex_proxy_env()
  local env = {
    NO_PROXY = vim.env.NO_PROXY or vim.env.no_proxy,
    no_proxy = vim.env.NO_PROXY or vim.env.no_proxy,
  }
  for _, key in ipairs(proxy_env_keys) do
    env[key] = false
  end
  return env
end

local function codex_proxy_env()
  -- 只有 ChatGPT/Codex OAuth 登录需要走本地代理；公司中转/API key 模式必须清掉代理，否则可能连不到公司网关。
  if not codex_uses_chatgpt_login() then
    return clear_codex_proxy_env()
  end

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

local codex_layout = "right"
local codex_tool_names = { "codex", "codex2", "codex3", "codex4" }
local hermes_tool_names = { "hermes", "hermes2", "hermes3", "hermes4" }
local primary_ai_tool_names = { "codex", "hermes" }
local ai_tool_names = {}
vim.list_extend(ai_tool_names, codex_tool_names)
vim.list_extend(ai_tool_names, hermes_tool_names)
local active_ai_name = "codex"
local active_ai_by_family = {
  codex = "codex",
  hermes = "hermes",
}

local function codex_tool_config()
  return {
    cmd = { codex_cmd() },
    env = codex_proxy_env(),
    is_proc = "\\<codex\\>",
    resume = { "resume" },
    continue = { "resume", "--last" },
    -- 禁止 Neovide/PATH 异常时自动弹浏览器；如果真的找不到命令，只显示错误提示。
    url = false,
  }
end

local function hermes_tool_config()
  return {
    cmd = { hermes_cmd() },
    env = clear_codex_proxy_env(),
    is_proc = "\\<hermes\\>",
    resume = { "--resume" },
    continue = { "--continue" },
    url = false,
  }
end

local function ai_tool_label(name)
  local hermes_index = name:match("^hermes(%d*)$")
  if hermes_index then
    return hermes_index == "" and "Hermes 1" or ("Hermes " .. hermes_index)
  end

  local index = name:match("^codex(%d*)$")
  if index then
    return index == "" and "Codex 1" or ("Codex " .. index)
  end
  return name
end

local function ai_tool_family(name)
  if name:match("^codex%d*$") then
    return "codex"
  end
  if name:match("^hermes%d*$") then
    return "hermes"
  end
end

local function ai_tool_index(name)
  for index, tool_name in ipairs(ai_tool_names) do
    if tool_name == name then
      return index
    end
  end
end

local function ai_family_tool_names(family)
  return family == "hermes" and hermes_tool_names or codex_tool_names
end

local function codex_split_opts(layout)
  return {
    width = layout == "right" and 0.40 or 0,
    height = layout == "bottom" and 0.30 or 0,
  }
end

local function codex_panel_wo()
  return {
    winfixwidth = false,
    winfixheight = false,
    winblend = 0,
    winhighlight = "Normal:Normal,NormalNC:NormalNC,EndOfBuffer:Normal,SignColumn:Normal",
  }
end

local function apply_codex_panel_highlights()
  vim.api.nvim_set_hl(0, "SidekickChat", { link = "Normal" })
end

local function set_codex_config_layout(layout)
  codex_layout = layout

  local win = require("sidekick.config").cli.win
  win.layout = layout
  win.split = vim.tbl_deep_extend("force", win.split or {}, codex_split_opts(layout))
  win.wo = vim.tbl_deep_extend("force", win.wo or {}, codex_panel_wo())
end

local send_to_visible_ai

local function visual_line_range(bufnr)
  local kind = require("sidekick.util").exit_visual_mode()
  if not kind then
    return nil
  end

  local from = vim.api.nvim_buf_get_mark(bufnr, "<")
  local to = vim.api.nvim_buf_get_mark(bufnr, ">")
  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end
  return from[1], to[1]
end

local function inline_code_question(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    vim.notify("Sidekick: current buffer has no file name", vim.log.levels.WARN)
    return
  end

  local selected_start, selected_end = visual_line_range(bufnr)
  local row = selected_start or vim.api.nvim_win_get_cursor(0)[1]
  local question = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  if not question:match("%S") then
    vim.notify("Sidekick: put the cursor on a comment question first", vim.log.levels.WARN)
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local before = opts.before or 10
  local after = opts.after or 5
  local start_row = selected_start or math.max(1, row - before)
  local end_row = selected_end or math.min(line_count, row + after)
  local context = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
  for index, line in ipairs(context) do
    context[index] = ("%5d  %s"):format(start_row + index - 1, line)
  end

  local prompt = table.concat({
    "你现在是一个逐行代码学习助手。",
    "",
    ("请直接编辑当前文件 `%s`，只在第 %d 行的问题注释下方插入回答注释。"):format(file, row),
    "",
    "严格要求：",
    "- 保持当前文件的注释风格。",
    "- 只插入解释性注释，不要修改、移动、删除或格式化任何已有代码。",
    "- 不要改写问题注释本身。",
    "- 回答要围绕附近代码，解释它在做什么、为什么这样写、关键变量和边界条件。",
    "- 如果问题不明确，也只插入一两行注释说明需要补充什么。",
    "",
    ("问题所在行：%d"):format(row),
    "问题内容：",
    question,
    "",
    selected_start
        and ("你手动选择的相关代码片段，左侧是真实行号，范围 %d-%d："):format(start_row, end_row)
      or ("相关代码片段，左侧是真实行号，范围 %d-%d："):format(start_row, end_row),
    "```",
    table.concat(context, "\n"),
    "```",
  }, "\n")

  send_to_visible_ai({
    text = require("sidekick.text").to_text(prompt),
    focus = true,
    submit = true,
  })
end

local function ai_states(name)
  local state = require("sidekick.cli.state")
  if name then
    return state.get({ name = name, attached = true })
  end

  local states = {}
  for _, tool_name in ipairs(ai_tool_names) do
    vim.list_extend(states, state.get({ name = tool_name, attached = true }))
  end
  return states
end

local function has_attached_ai(name)
  return #ai_states(name) > 0
end

local function target_ai_layout(name, layout)
  return layout or codex_layout
end

local function first_attached_ai_name(names)
  for _, name in ipairs(names) do
    if has_attached_ai(name) then
      return name
    end
  end
end

local function current_codex_layout()
  for _, state in ipairs(ai_states()) do
    if state.terminal and state.terminal.opts and state.terminal.opts.layout then
      return state.terminal.opts.layout
    end
  end
  return codex_layout
end

local function apply_codex_layout(layout)
  set_codex_config_layout(layout)

  for _, state in ipairs(ai_states()) do
    local terminal = state.terminal
    if terminal then
      local was_open = terminal:is_open()
      local was_focused = was_open and terminal:is_focused()
      if was_open then
        terminal:hide()
      end

      terminal.opts.layout = layout
      terminal.opts.split = vim.tbl_deep_extend("force", terminal.opts.split or {}, codex_split_opts(layout))
      terminal.opts.wo = vim.tbl_deep_extend("force", terminal.opts.wo or {}, codex_panel_wo())

      if was_open then
        terminal:show()
        if was_focused then
          terminal:focus()
        end
      end
    end
  end
end

local function set_ai_terminal_layout(terminal, layout)
  terminal.opts.layout = layout
  terminal.opts.split = vim.tbl_deep_extend("force", terminal.opts.split or {}, codex_split_opts(layout))
  terminal.opts.wo = vim.tbl_deep_extend("force", terminal.opts.wo or {}, codex_panel_wo())
end

local function sidekick_window_tool(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return nil
  end
  local ok, tool = pcall(vim.api.nvim_win_get_var, win, "sidekick_cli")
  return ok and tool or nil
end

local function ai_anchor_win()
  local current = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(current) and not sidekick_window_tool(current) then
    return current
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and not sidekick_window_tool(win) then
      return win
    end
  end
end

local function set_current_win_if_valid(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    return true
  end
  return false
end

local function show_ai_terminal_below(anchor_terminal, terminal)
  local anchor = anchor_terminal and anchor_terminal.win
  if not set_current_win_if_valid(anchor) then
    return false
  end

  terminal:start()
  if not terminal:is_running() or not terminal:buf_valid() then
    return false
  end
  if terminal:is_open() then
    terminal:hide()
    if not set_current_win_if_valid(anchor) then
      return false
    end
  end

  vim.cmd("rightbelow split")
  terminal.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(terminal.win, terminal.buf)
  vim.w[terminal.win].sidekick_cli = terminal.tool
  vim.w[terminal.win].sidekick_session_id = terminal.id
  set_ai_terminal_layout(terminal, "bottom")
  terminal:wo()
  return true
end

local function arrange_primary_ai_panels(layout, focus_name)
  local panels = {}
  for _, name in ipairs(primary_ai_tool_names) do
    for _, state in ipairs(ai_states(name)) do
      if state.terminal and state.terminal:is_open() then
        panels[#panels + 1] = { name = name, terminal = state.terminal }
        break
      end
    end
  end

  if #panels < 2 then
    return false
  end

  local anchor_win = ai_anchor_win()

  set_codex_config_layout(layout)
  for _, panel in ipairs(panels) do
    panel.terminal:hide()
  end

  for index, panel in ipairs(panels) do
    if index == 1 then
      if not set_current_win_if_valid(anchor_win) then
        set_current_win_if_valid(ai_anchor_win())
      end
      set_ai_terminal_layout(panel.terminal, layout)
      panel.terminal:show()
    elseif not show_ai_terminal_below(panels[index - 1].terminal, panel.terminal) then
      set_current_win_if_valid(ai_anchor_win())
    end
  end

  for _, state in ipairs(ai_states(focus_name or active_ai_name)) do
    local terminal = state.terminal
    if terminal and terminal:is_open() then
      terminal:focus()
      return true
    end
  end

  return true
end

local function move_ai_panels(layout)
  apply_codex_layout(layout)
  if arrange_primary_ai_panels(layout, active_ai_name) then
    return
  end

  for _, state in ipairs(ai_states(active_ai_name)) do
    local terminal = state.terminal
    if terminal and terminal:is_open() then
      terminal:focus()
      return
    end
  end
end

local function visible_ai_names()
  local names = {}
  for _, name in ipairs(primary_ai_tool_names) do
    for _, state in ipairs(ai_states(name)) do
      if state.terminal and state.terminal:is_open() then
        names[#names + 1] = name
        break
      end
    end
  end
  return names
end

local function focus_ai_after_send(names)
  if #names == 0 then
    return
  end

  local focus_name = vim.tbl_contains(names, active_ai_name) and active_ai_name or names[1]
  vim.schedule(function()
    for _, state in ipairs(ai_states(focus_name)) do
      local terminal = state.terminal
      if terminal and terminal:is_open() then
        terminal:focus()
        return
      end
    end
  end)
end

send_to_visible_ai = function(opts)
  opts = opts or {}
  set_codex_config_layout(codex_layout)

  local names = visible_ai_names()
  local has_visible_ai = #names > 0
  if #names == 0 then
    names = { active_ai_name }
  end

  for _, name in ipairs(names) do
    local send_opts = vim.deepcopy(opts)
    send_opts.name = name
    send_opts.focus = has_visible_ai and false or opts.focus
    require("sidekick.cli").send(send_opts)
  end

  if has_visible_ai and opts.focus ~= false then
    focus_ai_after_send(names)
  end
end

local function show_codex(layout, focus, name)
  name = name or active_ai_name
  active_ai_name = name
  local family = ai_tool_family(name)
  if family then
    active_ai_by_family[family] = name
  end
  layout = target_ai_layout(name, layout)
  focus = focus ~= false
  apply_codex_layout(layout)

  local shown_existing = false
  for _, state in ipairs(ai_states(name)) do
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
    require("sidekick.cli").show({ name = name, focus = focus })
  end

  arrange_primary_ai_panels(layout, focus and name or nil)
  vim.schedule(function()
    arrange_primary_ai_panels(layout, focus and name or nil)
  end)
end

local function toggle_ai_tool(name, layout, focus)
  active_ai_name = name
  local family = ai_tool_family(name)
  if family then
    active_ai_by_family[family] = name
  end

  for _, state in ipairs(ai_states(name)) do
    local terminal = state.terminal
    if terminal and terminal:is_open() then
      terminal:hide()
      return
    end
  end

  show_codex(layout, focus, name)
end

local function activate_ai_family(family, layout, focus)
  local names = ai_family_tool_names(family)
  local name = active_ai_by_family[family]
  if not name or not vim.tbl_contains(names, name) then
    name = names[1]
  end
  if not has_attached_ai(name) then
    name = first_attached_ai_name(names) or names[1]
  end
  show_codex(layout, focus, name)
end

local function new_ai_tool(family, layout, focus)
  local names = ai_family_tool_names(family)
  for _, name in ipairs(names) do
    if not has_attached_ai(name) then
      show_codex(layout, focus, name)
      return
    end
  end

  vim.notify("Sidekick: all " .. family .. " CLI slots are already attached", vim.log.levels.WARN)
  activate_ai_family(family, "bottom", true)
end

local function show_codex_slot(index, layout, focus)
  local name = codex_tool_names[index]
  if not name then
    vim.notify("Codex slot " .. tostring(index) .. " is not configured", vim.log.levels.WARN)
    return
  end
  show_codex(layout, focus, name)
end

local function show_hermes(layout, focus)
  activate_ai_family("hermes", layout, focus)
end

local function select_ai_tool()
  vim.ui.select(ai_tool_names, {
    prompt = "Active AI tool:",
    format_item = ai_tool_label,
  }, function(name)
    if name then
      show_codex(codex_layout, true, name)
    end
  end)
end

local function toggle_all_codex()
  local states = ai_states()
  local has_open = false

  for _, state in ipairs(states) do
    if state.terminal and state.terminal:is_open() then
      has_open = true
      break
    end
  end

  if has_open then
    for _, state in ipairs(states) do
      if state.terminal and state.terminal:is_open() then
        state.terminal:hide()
      end
    end
    return
  end

  local shown_existing = false
  apply_codex_layout(codex_layout)
  for _, state in ipairs(states) do
    if state.terminal then
      state.terminal:show()
      shown_existing = true
    end
  end

  if shown_existing then
    show_codex(codex_layout, true, active_ai_name)
  else
    show_codex(codex_layout, true)
  end
end

local function focus_or_blur_codex()
  for _, state in ipairs(ai_states(active_ai_name)) do
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

local function cycle_codex()
  local index = ai_tool_index(active_ai_name) or 1
  index = index % #ai_tool_names + 1
  show_codex(codex_layout, true, ai_tool_names[index])
end

return {
  {
    "folke/sidekick.nvim",
    config = function(_, opts)
      require("sidekick").setup(opts)
      apply_codex_panel_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("sidekick_codex_panel_highlights", { clear = true }),
        callback = function()
          vim.schedule(apply_codex_panel_highlights)
        end,
        desc = "Keep Sidekick Codex panel background aligned with normal windows",
      })

      vim.api.nvim_create_user_command("CodexRight", function()
        show_codex("right", true)
      end, { desc = "Move Sidekick Codex CLI to the right" })
      vim.api.nvim_create_user_command("CodexBottom", function()
        show_codex("bottom", true)
      end, { desc = "Move Sidekick Codex CLI to the bottom" })
      vim.api.nvim_create_user_command("CodexToggleLayout", function()
        toggle_codex_layout()
      end, { desc = "Toggle Sidekick Codex CLI right/bottom" })
      vim.api.nvim_create_user_command("CodexNext", function()
        cycle_codex()
      end, { desc = "Cycle Sidekick AI CLI slot" })
      vim.api.nvim_create_user_command("CodexNew", function()
        new_ai_tool("codex", nil, true)
      end, { desc = "Start a new Sidekick Codex CLI" })
      vim.api.nvim_create_user_command("AISelect", function()
        select_ai_tool()
      end, { desc = "Select active Sidekick AI CLI" })
      vim.api.nvim_create_user_command("Hermes", function()
        show_hermes(codex_layout, true)
      end, { desc = "Show Sidekick Hermes CLI" })
      vim.api.nvim_create_user_command("HermesNew", function()
        new_ai_tool("hermes", nil, true)
      end, { desc = "Start a new Sidekick Hermes CLI" })
      vim.api.nvim_create_user_command("CodexInlineQuestion", function()
        inline_code_question()
      end, { desc = "Ask active AI to answer the current comment inline" })
      vim.api.nvim_create_user_command("CodexInlineQuestionFull", function()
        inline_code_question({ before = 30, after = 80 })
      end, { desc = "Ask active AI to answer the current comment inline with more context" })
      for index, _ in ipairs(codex_tool_names) do
        vim.api.nvim_create_user_command("Codex" .. index, function()
          show_codex_slot(index, codex_layout, true)
        end, { desc = "Show Sidekick Codex CLI slot " .. index })
      end
    end,
    opts = {
      nes = {
        enabled = true,
      },
      cli = {
        tools = {
          codex = codex_tool_config(),
          codex2 = codex_tool_config(),
          codex3 = codex_tool_config(),
          codex4 = codex_tool_config(),
          hermes = hermes_tool_config(),
          hermes2 = hermes_tool_config(),
          hermes3 = hermes_tool_config(),
          hermes4 = hermes_tool_config(),
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
            winblend = 0,
            winhighlight = "Normal:Normal,NormalNC:NormalNC,EndOfBuffer:Normal,SignColumn:Normal",
          },
          layout = "right",
          split = {
            width = 0.40,
            height = 0,
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
        desc = "Sidekick: focus/blur active AI CLI",
      },
      {
        "<leader>ac",
        function()
          toggle_ai_tool("codex", codex_layout, true)
        end,
        mode = { "n", "x" },
        desc = "AI: toggle Codex",
      },
      {
        "<leader>ah",
        function()
          toggle_ai_tool("hermes", codex_layout, true)
        end,
        mode = { "n", "x" },
        desc = "AI: toggle Hermes",
      },
      {
        "<leader>ar",
        function()
          move_ai_panels("right")
        end,
        mode = { "n", "x" },
        desc = "AI: move Sidekick AI panels to right",
      },
      {
        "<leader>ab",
        function()
          move_ai_panels("bottom")
        end,
        mode = { "n", "x" },
        desc = "AI: move Sidekick AI panels to bottom",
      },
      {
        "<leader>al",
        function()
          toggle_codex_layout()
        end,
        mode = { "n", "x" },
        desc = "AI: toggle Sidekick AI CLI right/bottom",
      },
      {
        "<leader>aq",
        inline_code_question,
        mode = { "n", "x" },
        desc = "AI: answer current comment inline",
      },
      {
        "<leader>aQ",
        function()
          inline_code_question({ before = 30, after = 80 })
        end,
        mode = { "n", "x" },
        desc = "AI: answer current comment inline with more context",
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
              local text = require("sidekick.text").to_text(input .. "\n\n" .. selection)
              send_to_visible_ai({
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
          require("sidekick.cli").prompt({
            cb = function(_, text)
              if text then
                send_to_visible_ai({ text = text, focus = true })
              end
            end,
          })
        end,
        mode = { "n", "x" },
        desc = "AI: Sidekick prompt library",
      },
      {
        "<leader>af",
        function()
          send_to_visible_ai({ msg = "{file}", focus = true })
        end,
        mode = "n",
        desc = "AI: send file to Sidekick",
      },
      {
        "<leader>at",
        function()
          send_to_visible_ai({ msg = "{this}", focus = true })
        end,
        mode = { "n", "x" },
        desc = "AI: send current context to Sidekick",
      },
    },
  },
}
