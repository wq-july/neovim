-- code-companion AI 对话/编辑插件
-- 主力 chat 使用 Codex ACP + ChatGPT 订阅认证，默认模型 gpt-5.5。
-- inline/cmd 暂时保留 Ollama，作为低延迟本地/内网模型 fallback。
return {
  {
    "olimorris/codecompanion.nvim",
    version = "^19.0.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup({
        adapters = {
          acp = {
            codex = function()
              return require("codecompanion.adapters").extend("codex", {
                commands = {
                  default = {
                    -- 使用静态链接 musl 版，避免 Ubuntu 20.04 缺少 libssl.so.3 时误调用 npm GNU 版。
                    "/home/wq/.local/bin/codex-acp",
                  },
                },
                defaults = {
                  -- 使用 ~/.codex/auth.json 中已有的 ChatGPT 登录状态。
                  auth_method = "chatgpt",
                  timeout = 60000,
                  session_config_options = {
                    model = "gpt-5.5",
                  },
                },
              })
            end,
          },
          http = {
            ollama = function()
              return require("codecompanion.adapters").extend("ollama", {
                env = {
                  url = "http://100.84.29.6:11434",
                },
                schema = {
                  model = {
                    default = "qwen3.6",
                  },
                },
              })
            end,
          },
        },

        interactions = {
          chat = {
            adapter = {
              name = "codex",
              model = "gpt-5.5",
            },
          },
          inline = {
            adapter = {
              name = "ollama",
              model = "qwen3.6",
            },
          },
          cmd = {
            adapter = {
              name = "ollama",
              model = "qwen3.6",
            },
          },

        },
      })
    end,
  },
}
