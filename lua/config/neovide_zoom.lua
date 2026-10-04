-- Font/UI zoom for Neovide, including headless servers started by the launcher.
if not (vim.g.neovide or vim.env.NVIM_GUI == "neovide") then
  return
end

local initial_scale = vim.g.neovide_scale_factor or 1.0
local modes = { "n", "i", "v", "s", "c", "t" }
local function zoom(factor)
  local scale = (vim.g.neovide_scale_factor or initial_scale) * factor
  vim.g.neovide_scale_factor = math.max(0.25, math.min(4.0, scale))
end

-- Main keyboard + requires Shift on many layouts; also accept Ctrl+= and keypad +.
for _, lhs in ipairs({ "<C-+>", "<C-=>", "<C-kPlus>" }) do
  vim.keymap.set(modes, lhs, function()
    zoom(1.01)
  end, { silent = true, desc = "Neovide: increase font size" })
end
for _, lhs in ipairs({ "<C-->", "<C-kMinus>" }) do
  vim.keymap.set(modes, lhs, function()
    zoom(1 / 1.01)
  end, { silent = true, desc = "Neovide: decrease font size" })
end
vim.keymap.set(modes, "<C-0>", function()
  vim.g.neovide_scale_factor = initial_scale
end, { silent = true, desc = "Neovide: reset font size" })
