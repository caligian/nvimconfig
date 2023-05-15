local package_path = vim.split(package.path, ";")

filetype.lua = {
  compile = "lua5.1",

  repl = "lua5.1",

  server = {
    name = "lua_ls",
    config = {
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

  formatters = {
    {
      exe = "stylua",
      args = {
        "--call-parentheses None",
        "--collapse-simple-statement Always",
        "--line-endings Unix",
        "--column-width 80",
        "--quote-style AutoPreferDouble",
        "--indent-type Spaces",
        "--indent-width 2",
        "-",
      },
      stdin = true,
    },
  },

  bo = {
    shiftwidth = 2,
    tabstop = 2,
  },
}
