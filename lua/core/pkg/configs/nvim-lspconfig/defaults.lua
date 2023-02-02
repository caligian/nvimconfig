local package_path = vim.split(package.path, ';')

builtin.merge(user.lsp, {
    flags = {
        debounce_text_changes = 300,
    },
    server = {
        sumneko_lua = {
            settings = {
                Lua = {
                    path = package_path,
                    runtime = {
                        version = 'Lua 5.1',
                    },
                    workspace = {
                        library = package_path,
                    },
                    telemetry = {
                        enable = false
                    },
                    diagnostics = {
                        severity = {
                            { ["undefined-global"] = true },
                        },
                        disable = {
                            "lowercase-global",
                        },
                        globals = {
                            'vim',
                            'user',
                            'unpack',
                            'loadfile',
                            'builtin',
                            'yaml',
                            'path',
                            'listcomp',
                            'str',
                            'seq',
                            'dict',
                            'operator',
                            'json',
                            'types',
                            'file',
                            'dir',
                            'logging',
                            'logger',
                            'Date',
                            'Function',
                            'List',
                            'Map',
                            'MultiMap',
                            'OrderedMap',
                            'String',
                            'Seq',
                            'File',
                        }
                    }
                },
            }
        },
        pyright = true,
        solargraph = true,
        texlab = true,
        bashls = true,
    }
})
