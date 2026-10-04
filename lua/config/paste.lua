-- Keep Ctrl+V available for Vim's blockwise selection / literal input.
-- nvim_paste handles the active mode, including command-line and terminal paste.
local function paste_clipboard()
  local ok, text = pcall(vim.fn.getreg, "+")
  if not ok then
    vim.notify("Cannot read system clipboard: " .. tostring(text), vim.log.levels.WARN)
    return
  end
  if text == "" then
    vim.notify("System clipboard is empty or unavailable", vim.log.levels.WARN)
    return
  end
  local pasted, err = pcall(vim.api.nvim_paste, text, true, -1)
  if not pasted then
    vim.notify("Clipboard paste failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

vim.keymap.set({ "n", "x", "i", "c", "t" }, "<C-S-v>", paste_clipboard, {
  silent = true,
  desc = "Paste system clipboard",
})
