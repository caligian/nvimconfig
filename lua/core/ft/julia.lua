local julia = plugin.get("julia")

julia.compile = "julia %s"

julia.repl = "julia"

julia.lsp_server = {
    "julials",
    autostart = true,
    single_file_support = true,
    cmd = { "julia", "-e", "using LanguageServer; runserver()" },
}

return julia
