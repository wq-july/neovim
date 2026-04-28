-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ============================================
-- CodeCompanion AI 快捷键
-- ============================================

vim.keymap.set({ 'n', 'v' }, '<Leader>aa', '<cmd>CodeCompanionChat Toggle<cr>', {
  noremap = true,
  silent = true,
  desc = 'CodeCompanion: Toggle Chat',
})

vim.keymap.set({ 'n', 'v' }, '<Leader>ab', '<cmd>CodeCompanionActions<cr>', {
  noremap = true,
  silent = true,
  desc = 'CodeCompanion: Actions',
})

vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', {
  noremap = true,
  silent = true,
  desc = 'CodeCompanion: Add Selection',
})

-- 命令行缩写
vim.cmd('cab cc CodeCompanion')
