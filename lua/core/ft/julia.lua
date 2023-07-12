local julia = filetype.new "julia"

julia.compile = "julia"

julia.repl = "julia"

julia.lsp_server = {
    "julials",
    autostart = true,
    single_file_support = true,
    cmd = { "julia", "-e", "using LanguageServer; runserver()" },
}
