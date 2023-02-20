return {
  compile = "lua5.1",
  repl = "lua5.1",
  linters = "luacheck",

  server = {
    name = "lua_ls",
    config = require("core.lang.ft.lua.sumneko_lua"),
  },

  formatters = {
    {
      exe = "stylua",
      args = {
        "--line-endings Unix",
        "--column-width 100",
        "--quote-style AutoPreferDouble",
        "--call-parentheses Always",
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
