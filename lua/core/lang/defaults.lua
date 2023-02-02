-- Valid keys for <lang>.commands: build, compile, test, repl, debug
-- Valid keys for <lang>.server:   name, config
return {
    python = {
        commands = {
            build = false,
            compile = 'python',
            test = 'pytest',
            repl = 'python -q',
            debug = false,
        },
        server = {
            name = 'pyright',
            config = {},
        }
    },
    ruby = {
        commands = {
            build = false,
            compile = 'ruby',
            repl = 'irb --inf-ruby-mode',
            test = 'rspec',
        },
        server = {
            name = 'solargraph',
            config = {}
        },
    },
    lua = {
        commands = {
            build = false,
            compile = 'lua5.1',
            repl = 'lua5.1',
            test = false,
        },
        server = {
            name = 'sumneko_lua',
            config = require 'core.lang.lua',
        }
    },
    tex = {
        commands = {},
        server = { name = 'texlab' }
    },
    sh = {
        commands = {
            repl = user.shell,
            compile = user.shell,
        },
        server = { name = 'bashls' }
    }
}
