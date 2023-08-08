local tex = Filetype "text"

tex.lsp_server = "texlab"

tex.autocmds = {
    whitespace = function()
        vim.bo.textwidth = 80
        vim.bo.shiftwidth = 4
        vim.bo.tabstop = 4
    end,
}

tex.formatter = {
    "latexindent.pl -m -",
    stdin = true,
}

return tex
