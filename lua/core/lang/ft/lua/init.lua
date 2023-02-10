return {
  commands = {
    build = false,
    compile = 'lua5.1',
    repl = 'lua5.1',
    test = false,
  },
  server = {
    name = 'sumneko_lua',
    config = require('core.lang.ft.lua.sumneko_lua'),
  },
  linters = { 'luacheck' },
  formatters = {
    {
      exe = 'stylua',
      args = {
        '--line-endings Unix',
        '--column-width 100',
        '--quote-style AutoPreferSingle',
        '--call-parentheses Always',
        '--collapse-simple-statement Always',
        '--indent-type Spaces',
        '--indent-width 2',
        '-',
      },
      stdin = true,
    },
  },
  bo = {
    shiftwidth = 2,
    tabstop = 2,
  },
}
