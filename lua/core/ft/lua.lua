-- to be used with neovim

local package_path = vim.split(package.path, ";")
local formatter_path =
  Path.join(os.getenv "HOME", ".cargo", "bin", "stylua")
local formatter_cmd = formatter_path
  .. " "
  .. join({
    "--call-parentheses None",
    "--collapse-simple-statement Never",
    "--line-endings Unix",
    "--column-width 60",
    "--quote-style AutoPreferDouble",
    "--indent-type Spaces",
    "--indent-width 2",
  }, " ")

return {
  buf_opts = {
    shiftwidth = 2,
    tabstop = 2,
  },

  formatter = {
    buffer = "cat {path} | " .. formatter_cmd .. " -",
    workspace = formatter_cmd .. " {path}",
    dir = formatter_cmd .. " {path}",
  },

  compile = {
    buffer = "lua {path}",
    workspace = "luarocks --local build",
    dir = {
      [os.getenv "HOME" .. "/Repos/nvim%-utils"] = "cd ~/Repos/nvim-utils/ && ./build",
      [os.getenv "HOME" .. "/Repos/lua%-utils"] = "cd ~/Repos/lua-utils/ && ./build",
    },
  },

  repl = {
    buffer = "lua",
    workspace = "lua",
    dir = "lua",
  },

  server = {
    "lua_ls",
    config = {
      path = { "?.lua", "?/?.lua", "?/init.lua" },
      cmd = {
        Path.join(
          vim.fn.stdpath "config",
          "lsp_servers",
          "lua-language-server",
          "bin",
          "lua-language-server"
        ),
      },
      settings = {
        Lua = {
          runtime = {
            version = "Lua 5.1",
          },
          workspace = {
            library = list.append(
              list.filter(
                strsplit(vim.opt.rtp._value, ","),
                function(x)
                  return not x:match "local/share/nvim"
                    and not x:match "nvim/share/runtime"
                end
              ),
              Path.join(user.config_dir),
              Path.join(
                user.config_dir,
                "lua",
                "nvim-utils"
              ),
              Path.join(
                user.config_dir,
                "lua",
                "nvim-utils",
                "Buffer"
              ),
              Path.join(user.config_dir, "lua", "lua-utils"),
              Path.join(
                user.config_dir,
                "lua",
                "lua-utils",
                "types"
              )
            ),
          },
          telemetry = {
            enable = false,
          },
          diagnostics = {
            globals = { "nvim", "vim" },
            disable = {
              "lowercase-global",
              "undefined-global",
              "undefined-field",
              'inject-field',
            },
          },
        },
      },
    },
  },
}
