local transparent_enabled = false
local neovide_normal_opacity = 1.0
local neovide_window_opacity = 1.0

local function is_neovide_gui()
  return vim.g.neovide or vim.env.NVIM_GUI == "neovide"
end

local function set_bg(group, bg)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if not ok then
    hl = {}
  end
  hl.bg = bg
  pcall(vim.api.nvim_set_hl, 0, group, hl)
end

local function apply_neovide_window()
  if not is_neovide_gui() then
    return
  end

  vim.g.neovide_opacity = neovide_window_opacity
  vim.g.neovide_normal_opacity = neovide_normal_opacity
  vim.g.neovide_text_gamma = 0.9
  vim.g.neovide_text_contrast = 0.5

  vim.g.neovide_window_blurred = false

  vim.g.neovide_floating_shadow = false
  vim.g.neovide_floating_z_height = 4
  vim.g.neovide_floating_blur_amount_x = 0.0
  vim.g.neovide_floating_blur_amount_y = 0.0
end

local function apply_diagnostic_overrides()
  vim.cmd([[
    highlight DiagnosticWarn guifg=#7a7a7a ctermfg=244
    highlight DiagnosticVirtualTextWarn guifg=#666666 ctermfg=242 guibg=NONE
    highlight DiagnosticVirtualLinesWarn guifg=#666666 ctermfg=242 guibg=NONE
    highlight DiagnosticSignWarn guifg=#666666 ctermfg=242
    highlight DiagnosticUnderlineWarn gui=undercurl guisp=#555555

    highlight DiagnosticHint guifg=#5f5f5f ctermfg=240
    highlight DiagnosticVirtualTextHint guifg=#555555 ctermfg=240 guibg=NONE
    highlight DiagnosticVirtualLinesHint guifg=#555555 ctermfg=240 guibg=NONE
    highlight DiagnosticSignHint guifg=#555555 ctermfg=240
    highlight DiagnosticUnderlineHint gui=undercurl guisp=#444444

    highlight DiagnosticInfo guifg=#6f7f8f ctermfg=244
    highlight DiagnosticVirtualTextInfo guifg=#5f6f7f ctermfg=243 guibg=NONE
    highlight DiagnosticVirtualLinesInfo guifg=#5f6f7f ctermfg=243 guibg=NONE
    highlight DiagnosticSignInfo guifg=#5f6f7f ctermfg=243

    highlight DiagnosticUnnecessary guifg=#555555 ctermfg=240 gui=NONE
    highlight DiagnosticDeprecated guifg=#666666 ctermfg=242 gui=strikethrough

    highlight TroubleText guifg=#8a8a8a
    highlight TroubleSource guifg=#666666
    highlight TroubleCode guifg=#666666
    highlight TroublePos guifg=#666666
  ]])
end

local function apply_vscode_overrides()
  if transparent_enabled then
    -- 主界面尽量不画实色背景；Neovide 下由 normal_opacity 做整窗玻璃底。
    for _, group in ipairs({
      "Normal",
      "NormalNC",
      "SignColumn",
      "EndOfBuffer",
      "FoldColumn",
      "LineNr",
      "CursorLineNr",
      "CursorLine",
      "CursorLineFold",
      "CursorLineSign",
      "ColorColumn",
      "StatusLine",
      "StatusLineNC",
      "WinBar",
      "WinBarNC",
      "TabLine",
      "TabLineFill",
      "TabLineSel",
      "MsgArea",
      "MsgSeparator",
      "BufferLineBackground",
      "BufferLineFill",
      "BufferCurrent",
      "BufferCurrentIndex",
      "BufferCurrentMod",
      "BufferCurrentSign",
      "BufferCurrentTarget",
      "BufferVisible",
      "BufferVisibleIndex",
      "BufferVisibleMod",
      "BufferVisibleSign",
      "BufferVisibleTarget",
      "BufferInactive",
      "BufferInactiveIndex",
      "BufferInactiveMod",
      "BufferInactiveSign",
      "BufferInactiveTarget",
      "BufferTabpageFill",
      "BufferTabpages",
      "NvimTreeNormal",
      "NvimTreeNormalNC",
      "NvimTreeEndOfBuffer",
      "NvimTreeVertSplit",
      "NeoTreeNormal",
      "NeoTreeNormalNC",
      "SnacksDashboardNormal",
      "SnacksPicker",
      "SnacksPickerInput",
      "SnacksPickerList",
      "SnacksPickerPreview",
      "LazyNormal",
      "MasonNormal",
      "WhichKey",
      "WhichKeyNormal",
    }) do
      set_bg(group, "NONE")
    end

    -- 主编辑区在 Neovide 下给一点暗色玻璃底；终端中仍保持完全透明。
    vim.cmd([[
      highlight Normal guibg=NONE ctermbg=NONE guifg=#e8e8e8
      highlight NormalNC guibg=NONE ctermbg=NONE guifg=#d4d4d4
      highlight VertSplit guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
      highlight WinSeparator guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
      highlight Comment guifg=#8ad66d
      highlight Constant guifg=#ffd166
      highlight String guifg=#b6f07a
      highlight Number guifg=#ffd166
      highlight Identifier guifg=#9cdcfe
      highlight Function guifg=#7dd3fc
      highlight Statement guifg=#ff7ab2
      highlight Keyword guifg=#ff7ab2
      highlight Type guifg=#4ec9b0
      highlight Special guifg=#c586ff
      highlight StatusLine guibg=NONE ctermbg=NONE guifg=#d4d4d4
      highlight StatusLineNC guibg=NONE ctermbg=NONE guifg=#8a8a8a
      highlight TabLine guibg=NONE ctermbg=NONE guifg=#a0a0a0
      highlight TabLineFill guibg=NONE ctermbg=NONE
      highlight TabLineSel guibg=NONE ctermbg=NONE guifg=#ffffff
      highlight Pmenu guibg=#1e1e1e ctermbg=234
      highlight PmenuExtra guibg=#1e1e1e ctermbg=234
      highlight PmenuKind guibg=#1e1e1e ctermbg=234
      highlight PmenuSbar guibg=NONE ctermbg=NONE
      highlight PmenuThumb guibg=#5f5f5f ctermbg=240
      highlight PmenuSel guibg=#333333 guifg=#ffffff ctermbg=236
      highlight NormalFloat guibg=#1e1e1e ctermbg=234
      highlight FloatBorder guibg=#1e1e1e ctermbg=234 guifg=#6f6f6f ctermfg=242
      highlight FloatTitle guibg=#1e1e1e ctermbg=234 guifg=#e8e8e8
      highlight NoicePopup guibg=#1e1e1e ctermbg=234
      highlight NoicePopupBorder guibg=#1e1e1e ctermbg=234 guifg=#6f6f6f ctermfg=242
      highlight BlinkCmpMenu guibg=#1e1e1e ctermbg=234
      highlight BlinkCmpMenuBorder guibg=#1e1e1e ctermbg=234 guifg=#6f6f6f ctermfg=242
      highlight BlinkCmpMenuSelection guibg=#333333 guifg=#ffffff ctermbg=236
      highlight BlinkCmpDoc guibg=#1e1e1e ctermbg=234
      highlight BlinkCmpDocBorder guibg=#1e1e1e ctermbg=234 guifg=#6f6f6f ctermfg=242
      highlight BlinkCmpSignatureHelp guibg=#1e1e1e ctermbg=234
      highlight BlinkCmpSignatureHelpBorder guibg=#1e1e1e ctermbg=234 guifg=#6f6f6f ctermfg=242
      highlight NvimTreeNormal guibg=NONE ctermbg=NONE
      highlight NvimTreeEndOfBuffer guibg=NONE ctermbg=NONE
      highlight NvimTreeVertSplit guibg=NONE ctermbg=NONE
    ]])

    if vim.g.neovide then
      vim.cmd([[
        highlight Normal guibg=#1e1e1e ctermbg=NONE guifg=#e8e8e8
        highlight NormalNC guibg=#1b1b1b ctermbg=NONE guifg=#d4d4d4
      ]])
    end
  else
    -- 不透明主编辑区：需要纯专注、不想看到背景时使用。
    vim.cmd([[
      highlight Normal guibg=#1e1e1e ctermbg=234
      highlight NormalNC guibg=#1e1e1e ctermbg=234
      highlight VertSplit guibg=#3e3e42 ctermbg=237 guifg=#3e3e42 ctermfg=237
      highlight WinSeparator guibg=#3e3e42 ctermbg=237 guifg=#3e3e42 ctermfg=237
      highlight SignColumn guibg=#1e1e1e ctermbg=234
      highlight EndOfBuffer guibg=#1e1e1e ctermbg=234
      highlight FoldColumn guibg=#1e1e1e ctermbg=234
      highlight LineNr guibg=#1e1e1e ctermbg=234
      highlight CursorLineNr guibg=#1e1e1e ctermbg=234

      highlight NvimTreeNormal guibg=#252526 ctermbg=235
      highlight NvimTreeEndOfBuffer guibg=#252526 ctermbg=235
      highlight NvimTreeVertSplit guibg=#252526 ctermbg=235

      highlight BufferLineBackground guibg=#1e1e1e ctermbg=234
      highlight BufferLineFill guibg=#1e1e1e ctermbg=234

      highlight Pmenu guibg=#1e1e1e ctermbg=234
      highlight PmenuSel guibg=#094771 ctermbg=24
      highlight NormalFloat guibg=#1e1e1e ctermbg=234
      highlight FloatBorder guibg=#1e1e1e ctermbg=234 guifg=#3e3e42 ctermfg=237
      highlight FloatTitle guibg=#1e1e1e ctermbg=234 guifg=#d4d4d4
      highlight NoicePopup guibg=#1e1e1e ctermbg=234
      highlight NoicePopupBorder guibg=#1e1e1e ctermbg=234 guifg=#3e3e42 ctermfg=237
      highlight BlinkCmpMenu guibg=#1e1e1e ctermbg=234
      highlight BlinkCmpMenuBorder guibg=#1e1e1e ctermbg=234 guifg=#3e3e42 ctermfg=237
      highlight BlinkCmpMenuSelection guibg=#094771 guifg=#ffffff ctermbg=24
      highlight BlinkCmpDoc guibg=#1e1e1e ctermbg=234
      highlight BlinkCmpDocBorder guibg=#1e1e1e ctermbg=234 guifg=#3e3e42 ctermfg=237
      highlight BlinkCmpSignatureHelp guibg=#1e1e1e ctermbg=234
      highlight BlinkCmpSignatureHelpBorder guibg=#1e1e1e ctermbg=234 guifg=#3e3e42 ctermfg=237

      highlight BufferCurrent guibg=#1e1e1e guifg=#ffffff
      highlight BufferCurrentIndex guibg=#1e1e1e guifg=#569cd6
      highlight BufferCurrentMod guibg=#1e1e1e guifg=#dcdcaa
      highlight BufferCurrentSign guibg=#1e1e1e guifg=#569cd6
      highlight BufferCurrentTarget guibg=#1e1e1e guifg=#f48771
      highlight BufferVisible guibg=#252526 guifg=#cccccc
      highlight BufferVisibleIndex guibg=#252526 guifg=#569cd6
      highlight BufferVisibleMod guibg=#252526 guifg=#dcdcaa
      highlight BufferVisibleSign guibg=#252526 guifg=#569cd6
      highlight BufferVisibleTarget guibg=#252526 guifg=#f48771
      highlight BufferInactive guibg=#2d2d30 guifg=#858585
      highlight BufferInactiveIndex guibg=#2d2d30 guifg=#858585
      highlight BufferInactiveMod guibg=#2d2d30 guifg=#dcdcaa
      highlight BufferInactiveSign guibg=#2d2d30 guifg=#858585
      highlight BufferInactiveTarget guibg=#2d2d30 guifg=#f48771
      highlight BufferTabpageFill guibg=#1e1e1e guifg=#1e1e1e
      highlight BufferTabpages guibg=#1e1e1e guifg=#569cd6
    ]])
  end

  apply_diagnostic_overrides()
end

return {
  {
    -- VSCode 主题
    "Mofiqul/vscode.nvim",
    name = "vscode",
    priority = 1000,
    lazy = false,
    opts = {
      transparent = false,
      italic_comments = false,
      disable_nvimtree_bg = false,
      terminal_colors = true,
      color_overrides = {},
      group_overrides = {},
    },
    config = function(_, opts)
      vim.o.background = "dark"

      apply_neovide_window()

      require("vscode").setup(opts)
      vim.cmd.colorscheme("vscode")
      apply_vscode_overrides()

      vim.api.nvim_create_user_command("TransparentEnable", function()
        transparent_enabled = true
        apply_vscode_overrides()
        vim.notify("Transparent background enabled", vim.log.levels.INFO)
      end, {})

      vim.api.nvim_create_user_command("TransparentDisable", function()
        transparent_enabled = false
        apply_vscode_overrides()
        vim.notify("Transparent background disabled", vim.log.levels.INFO)
      end, {})

      vim.api.nvim_create_user_command("TransparentToggle", function()
        transparent_enabled = not transparent_enabled
        apply_vscode_overrides()
        vim.notify("Transparent background " .. (transparent_enabled and "enabled" or "disabled"), vim.log.levels.INFO)
      end, {})
    end,
  },
}
