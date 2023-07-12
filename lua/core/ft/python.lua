local python = filetype.new "python"

python.linters = "pylint"
python.formatter = { "black -q -", stdin = true }
python.test = "pytest"
python.repl = "ipython3"
python.lsp_server = "pyright"

python:add_autocmd {
    name = "python.whitespace",
    callback = function(au)
        buffer.setoption(au.buf, { shiftwidth = 4, tabstop = 4 })
    end,
}
