local erlang = Filetype 'erlang'

erlang.repl = {'erl'}

erlang.lsp_server = 'erlangls'

erlang.compile = 'erl'

erlang.formatter = {'rebar3 fmt -', stdin=true}

erlang.mappings = {
    compile_and_run_buffer = { 'n', '<leader>rc', function ()
        local bufnr = buffer.bufnr()
        Repl.if_running(bufnr, function (x)
            buffer.save(bufnr)
            Repl.send(x, sprintf('c("%s").', buffer.name()))
        end)
    end, {desc = 'compile and run buffer'}},
    filetype_compile_and_run_buffer = { 'n', '<localleader>rc', function ()
        local bufnr = buffer.bufnr()
        Repl.if_running('erlang', function (x)
            buffer.save(bufnr)
            Repl.send(x, sprintf('c("%s").', buffer.name()))
        end)
    end, {desc = 'compile and run buffer'}}
} 

return erlang
