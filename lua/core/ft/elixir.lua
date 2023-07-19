local elixir = filetype.get "elixir"

elixir.repl = {"iex", load_file = function (fname, make_file)
    fname = fname .. '.exs'
    make_file(fname)

    return sprintf("c(\"%s\")", fname)
end}

elixir.formatter = {
    "mix format - ",
    stdin = true,
}

elixir.compile = "iex"

elixir.lsp_server = {
    "elixirls",
    cmd = {
        "bash",
        path.join(user.data_dir, "lsp-servers", "elixir-ls", "scripts", "language_server.sh"),
    },
}
