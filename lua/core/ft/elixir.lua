local elixir = Filetype "elixir"

function is_project(current_dir)
    local prev_dir = vim.fn.fnamemodify(current_dir, ':h')
    local ls = dir.getallfiles(prev_dir)
    local check = path.join(prev_dir, 'mix.exs')

    for i = 1, #ls do
        if string.match(ls[i], check) then
            return true
        end
    end

    return false
end

elixir.repl = {
    { "iex", [is_project] = "cd ../ ; iex -S mix" },
}

-- elixir.repl = {"cd ../; iex -S mix", load_file = function (fname, make_file)
--     fname = fname .. '.exs'
--     make_file(fname)

--     return sprintf("c(\"%s\")", fname)
-- end}

elixir.formatter = {
    "mix format - ",
    stdin = true,
}

elixir.compile = "elixir"

elixir.lsp_server = {
    "elixirls",
    cmd = {
        "bash",
        path.join(user.data_dir, "lsp-servers", "elixir-ls", "scripts", "language_server.sh"),
    },
}

elixir.test = "cd ../ ; mix test"

elixir.mappings = {
    compile_and_run_buffer = {
        "n",
        "<leader>rc",
        function()
            local bufnr = buffer.bufnr()
            Repl.if_running(bufnr, function(x)
                buffer.save(bufnr)
                Repl.send(x, sprintf('c("%s")', buffer.name()))
            end)
        end,
        { desc = "compile and run buffer" },
    },
    filetype_compile_and_run_buffer = {
        "n",
        "<localleader>rc",
        function()
            local bufnr = buffer.bufnr()
            Repl.if_running("elixir", function(x)
                buffer.save(bufnr)
                Repl.send(x, sprintf('c("%s")', buffer.name()))
            end)
        end,
        { desc = "compile and run buffer" },
    },
}

return elixir


