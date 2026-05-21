local M = {}

local TERMINAL_COUNT = 99
local last_position = "bottom"
local last_terminal

local sidebar_fts = {
  ["NvimTree"] = true,
  ["neo-tree"] = true,
  ["Outline"] = true,
  ["aerial"] = true,
  ["trouble"] = true,
  ["Trouble"] = true,
  ["snacks_layout_box"] = true,
  ["snacks_picker_input"] = true,
  ["snacks_picker_list"] = true,
  ["snacks_picker_preview"] = true,
  ["snacks_dashboard"] = true,
  ["snacks_notif"] = true,
  ["snacks_terminal"] = true,
  ["help"] = true,
  ["qf"] = true,
  ["lazy"] = true,
  ["mason"] = true,
  ["yazi"] = true,
}

local function is_editor_win(win)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return false
  end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative and cfg.relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local bt = vim.bo[buf].buftype
  local ft = vim.bo[buf].filetype
  if bt ~= "" and bt ~= "acwrite" then
    return false
  end
  if sidebar_fts[ft] then
    return false
  end
  return true
end

local function terminal_host_win()
  local current = vim.api.nvim_get_current_win()
  if is_editor_win(current) then
    return current
  end

  local best_win, best_area = nil, -1
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor_win(win) then
      local area = vim.api.nvim_win_get_width(win) * vim.api.nvim_win_get_height(win)
      if area > best_area then
        best_area = area
        best_win = win
      end
    end
  end
  return best_win or current
end

local function terminal_win_opts(position)
  local vertical = position == "right" or position == "left"
  return {
    relative = "win",
    position = position,
    win = terminal_host_win(),
    width = vertical and 0.40 or 1,
    height = vertical and 1 or 0.30,
    stack = true,
    wo = {
      winfixwidth = vertical,
      winfixheight = not vertical,
      winbar = "",
      winhighlight = "Normal:Normal,NormalFloat:Normal,FloatBorder:WinSeparator",
    },
    on_buf = function(self)
      vim.api.nvim_create_autocmd("TermClose", {
        buffer = self.buf,
        once = true,
        callback = function()
          vim.schedule(function()
            if self:buf_valid() then
              self:close()
              vim.cmd.checktime()
            end
          end)
        end,
      })
    end,
  }
end

local function terminal_opts(position, cwd)
  return {
    cwd = cwd,
    count = TERMINAL_COUNT,
    auto_close = false,
    win = terminal_win_opts(position),
  }
end

local function buffer_terminal_id(buf)
  local ok, data = pcall(function()
    return vim.b[buf].snacks_terminal
  end)
  return ok and type(data) == "table" and data.id or nil
end

local function current_snacks_terminal()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "snacks_terminal" then
    for _, terminal in ipairs(require("snacks").terminal.list()) do
      if terminal.buf == buf then
        return terminal
      end
    end
  end
end

local function managed_terminal()
  if last_terminal and last_terminal.buf and vim.api.nvim_buf_is_valid(last_terminal.buf) then
    return last_terminal
  end

  local current = current_snacks_terminal()
  if current then
    last_terminal = current
    return current
  end

  for _, terminal in ipairs(require("snacks").terminal.list()) do
    if terminal.buf and buffer_terminal_id(terminal.buf) == TERMINAL_COUNT then
      last_terminal = terminal
      return terminal
    end
  end
end

function M.current()
  return managed_terminal()
end

local function terminal_position(terminal)
  if terminal and terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
    local meta = vim.w[terminal.win].snacks_win
    if meta and meta.position then
      return meta.position
    end
  end
  return terminal and terminal.opts and terminal.opts.position
end

local function apply_position(terminal, position)
  local win_opts = terminal_win_opts(position)
  if terminal:valid() then
    terminal:hide()
  end

  terminal.opts.relative = win_opts.relative
  terminal.opts.position = win_opts.position
  terminal.opts.win = win_opts.win
  terminal.opts.width = win_opts.width
  terminal.opts.height = win_opts.height
  terminal.opts.stack = win_opts.stack
  terminal.opts.wo = vim.tbl_deep_extend("force", terminal.opts.wo or {}, win_opts.wo)
  terminal:show()
  terminal:focus()
  vim.cmd.startinsert()
end

function M.open(position, cwd)
  position = position or last_position
  last_position = position

  local terminal = managed_terminal()
  if terminal then
    apply_position(terminal, position)
  else
    last_terminal = require("snacks").terminal(nil, terminal_opts(position, cwd))
  end
end

function M.toggle(position, cwd)
  position = position or last_position
  local terminal = managed_terminal()
  if terminal and terminal:valid() and terminal_position(terminal) == position then
    terminal:hide()
    return
  end
  M.open(position, cwd)
end

function M.toggle_layout(cwd)
  local terminal = managed_terminal()
  local position = terminal_position(terminal)
  M.open(position == "right" and "bottom" or "right", cwd)
end

function M.open_right(cwd)
  M.open("right", cwd)
end

function M.open_bottom(cwd)
  M.open("bottom", cwd)
end

function M.toggle_right(cwd)
  M.toggle("right", cwd)
end

function M.toggle_bottom(cwd)
  M.toggle("bottom", cwd)
end

function M.resize(delta)
  local terminal = managed_terminal()
  local win = terminal and terminal.win
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end

  local position = terminal_position(terminal)
  if position == "right" or position == "left" then
    local width = vim.api.nvim_win_get_width(win)
    vim.api.nvim_win_set_width(win, math.max(30, width + delta))
  else
    local height = vim.api.nvim_win_get_height(win)
    vim.api.nvim_win_set_height(win, math.max(8, height + delta))
  end
end

return M
