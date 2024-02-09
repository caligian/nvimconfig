local package_path = vim.split(package.path, ";")
local formatter_path = Path.join(os.getenv "HOME", ".cargo", "bin", "stylua")
local formatter_cmd = formatter_path .. " "
.. join({
  "--call-parentheses None",
  "--collapse-simple-statement Never",
  "--line-endings Unix",
  "--column-width 120",
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
    workspace = function(ws)
      local kids = strsplit(vim.fn.glob(ws .. "/*.rockspec"), "\n")
      local cmd = "luarocks --local build"
      return cmd
    end,
  },

  repl = {
    buffer = "lua",
    workspace = "lua",
    dir = "lua",
  },

  server = {
    "lua_ls",
    config = {
      path = {'?.lua', '?/?.lua', '?/init.lua'},
      cmd = {
        Path.join(vim.fn.stdpath "config", "lsp_servers", "lua-language-server", "bin", "lua-language-server"),
      },
      settings = {
        Lua = {
          runtime = {
            version = "Lua 5.1",
          },
          workspace = {
            library = list.append(
            list.filter(strsplit(vim.opt.rtp._value, ','), function (x)
              return not x:match 'local/share/nvim'
            end),
            Path.join(user.config_dir),
            Path.join(user.config_dir, 'lua', 'nvim-utils'),
            Path.join(user.config_dir, 'lua', 'nvim-utils', 'Buffer'),
            Path.join(user.config_dir, 'lua', 'lua-utils'),
            Path.join(user.config_dir, 'lua', 'lua-utils', 'types'))
          },
          telemetry = {
            enable = false,
          },
          diagnostics = {
            globals = {'nvim', 'vim' },
            severity = { { ["undefined-global"] = false } },
            disable = {
              "lowercase-global",
              "undefined-global",
            },
          },
        },
      },
    },
  },
}
