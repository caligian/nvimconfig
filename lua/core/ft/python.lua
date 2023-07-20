local python = Filetype.get "python"

python.linters = "pylint"

python.formatter = { "black -q -", stdin = true }

python.test = "pytest"

python.repl = {"ipython3", load_file = function (fname, make_file)
    local new_fname = fname .. '.py'
    make_file(new_fname)

    return sprintf("%%load %s\n", new_fname)
end}

python.lsp_server = "pyright"

python.compile = "python3"

python.autocmds = {
    whitespace = function (au)
        buffer.set_option(au.buf, { shiftwidth = 4, tabstop = 4 })
    end
}
