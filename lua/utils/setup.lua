function builtin.clone(repo, args, dest)
    if type(args) == 'table' then args = table.concat(args, ' ') end

    local cmd = sprintf('git clone %s %s %s', repo, args, dest)
    local g = Process(cmd)

    g:setup {
        on_exit = function(p)
            if #p.stderr > 0 then
                error(table.concat(p.stderr, "\n"))
            else
                local b = Buffer('git_output_buffer', true)
                b:setlines(0, -1, p.stdout)
                b:split()
            end
        end
    }
    g:run()
end

builtin.clone('https://github.com/caligian/home_bin', {}, './home_bin')
