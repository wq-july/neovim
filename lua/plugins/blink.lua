local function format_after_completion()
  vim.schedule(function()
    local ok, conform = pcall(require, "conform")
    if not ok then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
      return
    end
    if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
      return
    end
    -- 防止远程大文件在每次确认补全后频繁全量格式化造成卡顿。
    if vim.api.nvim_buf_line_count(bufnr) > 3000 then
      return
    end

    conform.format({
      bufnr = bufnr,
      async = true,
      timeout_ms = 1200,
      lsp_format = "fallback",
      quiet = true,
    })
  end)
end

return {
 {
  "saghen/blink.cmp",
  opts = {
     keymap = {
       preset = "none", -- 关闭默认预设，自定义按键
       -- 补全确认使用 Alt-y；Space/Enter/Ctrl-y/标点都保持原有用途，避免和普通输入、换行、滚动冲突。
       -- Tab / Shift-Tab 只负责在补全菜单里向下 / 向上选择；菜单关闭时保持原本缩进行为。
       ["<Tab>"] = { "select_next", "fallback" },
       ["<S-Tab>"] = { "select_prev", "fallback" },
       -- LazyVim/blink 默认会给 Ctrl-y 绑定 select_and_accept；这里显式禁用，保留原本滚动/编辑习惯。
       ["<C-y>"] = false,
       ["<M-y>"] = {
         function(cmp)
           if cmp.is_menu_visible and cmp.is_menu_visible() then
             return cmp.accept({ callback = format_after_completion })
           end
         end,
         "fallback",
       },
       -- 手动触发补全/文档；不要 fallback，避免 Ctrl+Space 被终端/tmux 当成 NUL/^@ 插入。
       ["<C-Space>"] = { "show", "show_documentation" },
       -- 许多终端/tmux 会把 Ctrl+Space 编码成 Ctrl-@；一起兜底映射。
       ["<C-@>"] = { "show", "show_documentation" },
     },
      sources = {
        providers = {
          lsp = {
            -- 防止接受补全项时顺手应用 additionalTextEdits。
            -- 典型副作用就是 Pyright/clangd 自动插入 import / #include。
            transform_items = function(_, items)
              for _, item in ipairs(items) do
                item.additionalTextEdits = nil
                if item.textEdit then
                  item.textEdit.additionalTextEdits = nil
                end
              end
              return items
            end,
          },
        },
      },
      appearance = {
        nerd_font_variant = "normal",
      },
      completion = {
        -- 恢复 blink.cmp 的自动补全体验：输入关键字/触发字符时自动弹出菜单，
        -- 不再依赖 <C-Space> 手动触发。
        menu = {
          auto_show = true,
          border = "rounded",
          winblend = 0,
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
        },
        trigger = {
          prefetch_on_insert = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        documentation = {
          -- 远程 SSH 性能优化：不要自动弹出大块解释/文档浮窗，需要时手动查看 hover。
          auto_show = false,
          window = {
            border = "rounded",
            winblend = 0,
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder",
          },
        },
        ghost_text = {
          enabled = false,
        },
      },
      signature = {
        enabled = false,
        window = {
          border = "rounded",
          winblend = 0,
          winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
        },
      },
  
  }
 }


  -- {
  --   "saghen/blink.cmp",
  --   -- version = "1.*",
  --
  --   dependencies = {
  --     "nvim-tree/nvim-web-devicons",
  --     "onsails/lspkind.nvim",
  --     "fang2hou/blink-copilot",
  --     "folke/lazydev.nvim",
  --     -- "rafamadriz/friendly-snippets",
  --   },
  --
  --   ---@module "blink.cmp"
  --   ---@type blink.cmp.Config
  --   opts = {
  --
  --     ------------------------------------------------------------------
  --     -- 1. 键位：Enter 确认，Tab / Shift-Tab 选择
  --     ------------------------------------------------------------------
  --     keymap = {
  --       preset = "none", -- 关闭默认预设，自定义按键
  --
  --       -- Space/Enter/Ctrl-y/标点不绑定补全确认，避免普通输入、换行、滚动冲突。
  --       ["<Tab>"] = { "select_next", "fallback" },
  --       ["<S-Tab>"] = { "select_prev", "fallback" },
  --       ["<C-y>"] = false,
  --       ["<M-y>"] = { "accept", "fallback" },
  --       ["<C-Space>"] = { "show", "show_documentation" },
  --       ["<C-@>"] = { "show", "show_documentation" },
  --     },
  --
  --     ------------------------------------------------------------------
  --     -- 2. 外观（安全）
  --     ------------------------------------------------------------------
  --     appearance = {
  --       nerd_font_variant = "normal",
  --     },
  --
  --     ------------------------------------------------------------------
  --     -- 3. 补全来源（你这部分设计是“对的”）
  --     ------------------------------------------------------------------
  --     sources = {
  --       default = function()
  --         local ok, node = pcall(vim.treesitter.get_node)
  --         if ok and node and vim.tbl_contains(
  --           { "comment", "line_comment", "block_comment" },
  --           node:type()
  --         ) then
  --           return { "buffer" }
  --         end
  --         return {
  --           "lazydev",
  --           "copilot",
  --           "lsp",
  --           "path",
  --           "snippets",
  --           "buffer",
  --         }
  --       end,
  --
  --       per_filetype = {
  --         -- example: special completion providers per filetype
  --       },
  --
  --       providers = {
  --         ----------------------------------------------------------------
  --         -- LazyDev（Lua / Neovim API）
  --         ----------------------------------------------------------------
  --         lazydev = {
  --           name = "LazyDev",
  --           module = "lazydev.integrations.blink",
  --           score_offset = 95,
  --         },
  --
  --         ----------------------------------------------------------------
  --         -- Copilot
  --         ----------------------------------------------------------------
  --         copilot = {
  --           name = "copilot",
  --           module = "blink-copilot",
  --           score_offset = 100,
  --           async = true,
  --           opts = {
  --             kind_icon = "",
  --             kind_hl = "DevIconCopilot",
  --           },
  --         },
  --
  --         ----------------------------------------------------------------
  --         -- LSP
  --         ----------------------------------------------------------------
  --         lsp = {
  --           score_offset = 60,
  --           fallbacks = { "buffer" },
  --
  --           -- 过滤 Text（非常推荐保留）
  --           transform_items = function(_, items)
  --             local kinds = require("blink.cmp.types").CompletionItemKind
  --             return vim.tbl_filter(function(item)
  --               return item.kind ~= kinds.Text
  --             end, items)
  --           end,
  --         },
  --
  --         ----------------------------------------------------------------
  --         -- Path / Buffer / Snippet
  --         ----------------------------------------------------------------
  --         path = {
  --           score_offset = 90,
  --         },
  --
  --         snippets = {
  --           score_offset = 70,
  --           should_show_items = function(ctx)
  --             return ctx.trigger.initial_kind ~= "trigger_character"
  --           end,
  --         },
  --
  --         buffer = {
  --           score_offset = 20,
  --         },
  --       },
  --     },
  --
  --     ------------------------------------------------------------------
  --     -- 4. 补全行为（保留核心）
  --     ------------------------------------------------------------------
  --     completion = {
  --       list = {
  --         selection = {
  --           preselect = true,
  --           auto_insert = false,
  --         },
  --       },
  --
  --       menu = {
  --         border = "rounded",
  --         max_height = 15,
  --       },
  --
  --       documentation = {
  --         auto_show = true,
  --         auto_show_delay_ms = 200,
  --         window = {
  --           border = "rounded",
  --         },
  --       },
  --
  --       ghost_text = {
  --         enabled = true,
  --       },
  --     },
  --
  --     ------------------------------------------------------------------
  --     -- 5. Signature Help（C++ / clangd 强相关）
  --     ------------------------------------------------------------------
  --     signature = {
  --       enabled = true,
  --       window = {
  --         border = "single",
  --       },
  --     },
  --
  --     ------------------------------------------------------------------
  --     -- 6. Fuzzy（默认即可）
  --     ------------------------------------------------------------------
  --     fuzzy = {
  --       implementation = "prefer_rust_with_warning",
  --     },
  --
  --     ------------------------------------------------------------------
  --     -- 7. cmdline：完全交给 LazyVim
  --     ------------------------------------------------------------------
  --     -- cmdline = nil
  --   },
  --
  --   opts_extend = { "sources.default" },
  -- },
}
