local package_path = vim.split(package.path, ";")
local formatter_path = path.join(os.getenv "HOME", ".cargo", "bin", "stylua")
local formatter_args = array.join({
  "--call-parentheses None",
  "--collapse-simple-statement Always",
  "--line-endings Unix",
  "--column-width 80",
  "--quote-style AutoPreferDouble",
  "--indent-type Spaces",
  "--indent-width 2",
  "-",
}, " ")
local formatter_cmd = formatter_path .. ' ' .. formatter_args

filetype.lua = {
  compile = "lua5.1",

  repl = "lua5.1",

  server = {
    "lua_ls",
    config = {
      cmd = {
        path.join(
          vim.fn.stdpath "data",
          "lua-language-server",
          "bin",
          "lua-language-server"
        ),
      },
      settings = {
        Lua = {
          path = package_path,
          runtime = {
            version = "Lua 5.1",
          },
          workspace = {
            library = package_path,
          },
          telemetry = {
            enable = false,
          },
          diagnostics = {
            severity = { { ["undefined-global"] = false } },
            disable = { "lowercase-global", "undefined-global" },
          },
        },
      },
    },
  },

  formatter = {
    formatter_cmd,
    stdin = true
  },

  bo = {
    shiftwidth = 2,
    tabstop = 2,
  },
}
