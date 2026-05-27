-- 彩虹括号
-- LazyVim 默认未自带
-- 远程 Neovim 0.12 上，vim.treesitter.get_parser() 对无 parser 的特殊 buffer
-- 可能返回 nil 而不是抛错；rainbow-delimiters 当前版本会继续调用 parser:register_cbs()
-- 导致 snacks/noice/lazy 等特殊窗口触发 `attempt to index local parser`。
-- 因此只在普通 buffer 且确实能拿到 Tree-sitter parser 时启用。
return {
  "HiPhish/rainbow-delimiters.nvim",
  main = "rainbow-delimiters.setup",
  submodules = false,
  opts = {
    condition = function(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
      end

      -- 跳过 picker、noice、lazy 等临时/特殊窗口。
      if vim.bo[bufnr].buftype ~= "" then
        return false
      end

      local ft = vim.bo[bufnr].filetype
      if ft == "" then
        return false
      end

      local lang = vim.treesitter.language.get_lang(ft)
      if not lang then
        return false
      end

      local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
      return ok and parser ~= nil
    end,
  },
}
