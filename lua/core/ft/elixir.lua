local elixir = filetype.new "elixir"

elixir.repl = "iex"

elixir.formatter = {
    "mix format - ",
    stdin = true,
}

elixir.compile = "iex"

elixir.lsp_server = {
    "elixirls",
    cmd = {
        "bash",
        path.join(
            user.data_dir,
            "lsp-servers",
            "elixir-ls",
            "scripts",
            "language_server.sh"
        ),
    },
}
