return {
    commands = {
        repl = user.shell,
        compile = user.shell,
    },
    server = { name = 'bashls' },
    linters = { 'shellcheck' },
}
