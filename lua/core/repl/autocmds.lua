user.builtin.autocmd.create('VimLeave', '*', function ()
    for _, repl in pairs(user.builtin.repl.ids) do
        user.builtin.repl.stop_terminal(repl.id)
    end
end, {name = 'stop_all_repls'})
