return {
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
    },
    linters = { 'pylint', 'flake8', 'mypy', 'pylama' },
}
