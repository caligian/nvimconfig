local package_path = vim.split(package.path, ';')

return {
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
                    { ["undefined-global"] = false },
                },
                disable = {
                    "lowercase-global",
                },
                globals = {
                    'vim',
                    'user',
                    'unpack',
                    'loadfile',
                    'V',
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
                    'Keybinding',
                    'Autocmd',
                    'REPL',
                }
            }
        },
    }
}
