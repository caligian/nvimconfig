local rust = Filetype 'rust'

rust.repl = {'evcxr', on_input = function (s)
    s[#s + 1] = "\n"
    return s
end}

rust.compile = 'cargo run'
rust.lsp_server = 'rust_analyzer'

return rust
