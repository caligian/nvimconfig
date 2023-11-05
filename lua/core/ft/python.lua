local python = filetype("python")

python.linters = "pylint %s"

python.formatter = { "black -q -", stdin = true }

python.test = "pytest %s"

python.repl = {
    {"ipython3"}, 
    on_input = function (lines)
        return append(filter(lines, function (x) return #x > 0 end), "")
    end,
    load_file = function (fname, make_file)
        local new_fname = fname .. '.py'
        make_file(new_fname)

        return sprintf("%%load %s\n\n", new_fname)
    end
}

python.lsp_server = "pyright"

python.compile = "python3 %s"

python.autocmds = {
    whitespace = function (au)
        buffer.set_option(au.buf, { shiftwidth = 4, tabstop = 4, expandtab = true })
    end
}

return python
