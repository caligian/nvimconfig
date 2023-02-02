return {
    commands = {
        build = false,
        compile = 'lua5.1',
        repl = 'lua5.1',
        test = false,
    },
    server = {
        name = 'sumneko_lua',
        config = require 'core.lang.ft.lua.sumneko_lua',
    }
}
