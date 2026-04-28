-- code-companion AI对话插件（Ollama）
return {
  {
    'olimorris/codecompanion.nvim',
    version = '^19.0.0',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('codecompanion').setup({
        -- 适配器
        adapters = {
          http = {
            ollama = function()
              return require('codecompanion.adapters').extend('ollama', {
                env = {
                  url = 'http://127.0.0.1:11434',
                },
              })
            end,
          },
        },

        -- 交互策略
        strategies = {
          chat = {
            adapter = 'ollama',
            model = 'qwen3.6',
          },
          actions = {
            adapter = 'ollama',
            model = 'qwen3.6',
          },
          inline = {
            adapter = 'ollama',
            model = 'qwen3.6',
          },
        },
      })
    end,
  },
}
