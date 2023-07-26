local js = Filetype.get 'javascript'
js.compile = 'node'
js.repl = 'node'
js.lsp_server = 'tsserver'
js.linters = {'eslint'}
js.autocmds = {
    buffer_options = function (au)
        local bufnr = au.buf
        buffer.set_option(bufnr, 'expandtab', true)
    end
}
