-- nvim-scrollbar: 缩略图式滚动条
-- LazyVim 默认未自带
return {
  "petertriho/nvim-scrollbar",
  opts = {
    providers = {
      gitsigns = true, -- 显示 Git hunk
      search = true,   -- 显示搜索匹配位置
    },
    marks = {
      Search = { color = "#CBA6F7" },
      GitAdd = { text = "┃" },
      GitChange = { text = "┃" },
      GitDelete = { text = "_" },
    },
  },
}
