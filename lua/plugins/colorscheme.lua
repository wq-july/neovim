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

    -- 浮窗/菜单也透明：补全、函数解释、诊断浮窗会透出终端背景。
    -- 选中项保留蓝色底，避免补全菜单当前项看不清。
    vim.cmd([[
      highlight VertSplit guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
      highlight WinSeparator guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
      highlight Pmenu guibg=NONE ctermbg=NONE
      highlight PmenuExtra guibg=NONE ctermbg=NONE
      highlight PmenuKind guibg=NONE ctermbg=NONE
      highlight PmenuSbar guibg=NONE ctermbg=NONE
      highlight PmenuThumb guibg=#3e3e42 ctermbg=237
      highlight PmenuSel guibg=#094771 ctermbg=24
      highlight NormalFloat guibg=NONE ctermbg=NONE
      highlight FloatBorder guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
      highlight FloatTitle guibg=NONE ctermbg=NONE
      highlight BlinkCmpMenu guibg=NONE ctermbg=NONE
      highlight BlinkCmpMenuBorder guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
      highlight BlinkCmpDoc guibg=NONE ctermbg=NONE
      highlight BlinkCmpDocBorder guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
      highlight BlinkCmpSignatureHelp guibg=NONE ctermbg=NONE
      highlight BlinkCmpSignatureHelpBorder guibg=NONE ctermbg=NONE guifg=#3e3e42 ctermfg=237
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
        vim.g.neovide_opacity = 0.88
        vim.g.neovide_normal_opacity = 0.88
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
