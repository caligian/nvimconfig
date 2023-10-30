local ocaml = 'ocaml'

ocaml.repl = {
    "utop",
    on_input = function(s)
        if not s[#s]:match ";;$" then
            return s, ";;")
        end
        return s
    end,
}

ocaml.lsp_server = 'ocamllsp'

ocaml.formatter = {
    "ocamlformat - ",
    stdin = true,
}

ocaml.autocmds = {
    buffer_options = function (au)
        buffer.set_option(au.buf, 'tabstop', 4)
        buffer.set_option(au.buf, 'shiftwidth', 4)
    end
}

return ocaml
