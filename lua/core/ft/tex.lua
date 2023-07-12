local tex = filetype.new "text"

tex.lsp_server = "texlab"

tex:add_autocmd {
    name = "whitespace",
    callback = function()
        vim.bo.textwidth = 80
        vim.bo.shiftwidth = 4
        vim.bo.tabstop = 4
    end,
}

tex.formatter = {
    "latexindent.pl -m -",
    stdin = true,
}
