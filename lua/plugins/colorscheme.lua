local transparent_enabled = true

local function set_bg(group, bg)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if not ok then
    hl = {}
  end
  hl.bg = bg
  pcall(vim.api.nvim_set_hl, 0, group, hl)
end

local function apply_vscode_overrides()
  if transparent_enabled then
    -- 透明主编辑区：配合 Neovide/终端窗口透明度，可以隐约看到背后的教材。
    for _, group in ipairs({
      "Normal",
      "NormalNC",
      "SignColumn",
      "EndOfBuffer",
      "FoldColumn",
      "LineNr",
      "CursorLineNr",
      "BufferLineBackground",
      "BufferLineFill",
      "BufferCurrent",
      "BufferCurrentIndex",
      "BufferCurrentMod",
      "BufferCurrentSign",
      "BufferCurrentTarget",
      "BufferTabpageFill",
      "BufferTabpages",
    }) do
      set_bg(group, "NONE")
    end

    -- 主编辑区保持透明；浮窗使用半透明玻璃色，配合 Neovide 的 floating blur 提升可读性。
    vim.cmd([[
      highlight Normal guibg=NONE ctermbg=NONE guifg=#f2f7ff
      highlight NormalNC guibg=NONE ctermbg=NONE guifg=#dce8ff
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
      highlight Pmenu guibg=#1e1e1e ctermbg=234 blend=25
      highlight PmenuExtra guibg=#1e1e1e ctermbg=234 blend=25
      highlight PmenuKind guibg=#1e1e1e ctermbg=234 blend=25
      highlight PmenuSbar guibg=NONE ctermbg=NONE
      highlight PmenuThumb guibg=#64748b ctermbg=240 blend=15
      highlight PmenuSel guibg=#2d3a46 guifg=#ffffff ctermbg=24 blend=15
      highlight NormalFloat guibg=#1e1e1e ctermbg=234 blend=25
      highlight FloatBorder guibg=#1e1e1e ctermbg=234 guifg=#7dd3fc ctermfg=117 blend=25
      highlight FloatTitle guibg=#1e1e1e ctermbg=234 guifg=#f2f7ff blend=25
      highlight NoicePopup guibg=#1e1e1e ctermbg=234 blend=25
      highlight NoicePopupBorder guibg=#1e1e1e ctermbg=234 guifg=#7dd3fc ctermfg=117 blend=25
      highlight BlinkCmpMenu guibg=#1e1e1e ctermbg=234 blend=25
      highlight BlinkCmpMenuBorder guibg=#1e1e1e ctermbg=234 guifg=#7dd3fc ctermfg=117 blend=25
      highlight BlinkCmpMenuSelection guibg=#2d3a46 guifg=#ffffff ctermbg=24 blend=15
      highlight BlinkCmpDoc guibg=#1e1e1e ctermbg=234 blend=25
      highlight BlinkCmpDocBorder guibg=#1e1e1e ctermbg=234 guifg=#7dd3fc ctermfg=117 blend=25
      highlight BlinkCmpSignatureHelp guibg=#1e1e1e ctermbg=234 blend=25
      highlight BlinkCmpSignatureHelpBorder guibg=#1e1e1e ctermbg=234 guifg=#7dd3fc ctermfg=117 blend=25
      highlight NvimTreeNormal guibg=NONE ctermbg=NONE
      highlight NvimTreeEndOfBuffer guibg=NONE ctermbg=NONE
      highlight NvimTreeVertSplit guibg=NONE ctermbg=NONE
    ]])
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

      highlight Pmenu guibg=#252526 ctermbg=235
      highlight PmenuSel guibg=#094771 ctermbg=24
      highlight NormalFloat guibg=#252526 ctermbg=235
      highlight FloatBorder guibg=#252526 ctermbg=235 guifg=#3e3e42 ctermfg=237

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
end

return {
  {
    -- VSCode 主题
    "Mofiqul/vscode.nvim",
    name = "vscode",
    priority = 1000,
    lazy = false,
    opts = {
      transparent = true,
      italic_comments = false,
      disable_nvimtree_bg = true,
      terminal_colors = true,
      color_overrides = {},
      group_overrides = {},
    },
    config = function(_, opts)
      vim.o.background = "dark"

      -- Neovide 下让整个 GUI 窗口轻微透明；终端版 Neovim 仍需由终端模拟器控制透明度。
      if vim.g.neovide then
        vim.g.neovide_opacity = 0.86
        vim.g.neovide_normal_opacity = 0.86
        vim.g.neovide_text_gamma = 0.85
        vim.g.neovide_text_contrast = 0.45
        vim.g.neovide_floating_shadow = false
        vim.g.neovide_floating_z_height = 4
        vim.g.neovide_floating_blur_amount_x = 6.0
        vim.g.neovide_floating_blur_amount_y = 6.0
      end

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
