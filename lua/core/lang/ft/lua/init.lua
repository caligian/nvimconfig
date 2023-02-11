return {
  compile = 'lua5.1',
  repl = 'lua5.1',
  linters = 'luacheck',

  server = {
    name = 'sumneko_lua',
    config = require('core.lang.ft.lua.sumneko_lua'),
  },

  formatters = {
    {
      exe = 'stylua',
      args = {
        '--line-endings Unix',
        '--column-width 100',
        '--quote-style AutoPreferSingle',
        '--call-parentheses Always',
        '--indent-type Spaces',
        '--indent-width 2',
        '-',
      },
      stdin = true,
    },
  },

  bo = {
    shiftwidth = 2,
    tabwidth = 2,
  },
}
