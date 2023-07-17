local python = filetype.get "python"

python.linters = "pylint"

python.formatter = { "black -q -", stdin = true }

python.test = "pytest"

python.repl = {"ipython3", on_input = function (x)
    return array.map(x, function (s)
        if #s == 0 then
            return '    '
        else
            return s
        end
    end)
end}

python.lsp_server = "pyright"

python.compile = "ipython3"

python.autocmds = {
    whitespace = function (au)
        buffer.set_option(au.buf, { shiftwidth = 4, tabstop = 4 })
    end
}

return function ()
    python:load_autocmds()
end
