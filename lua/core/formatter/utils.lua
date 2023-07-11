formatter = formatter or { formatter_processes = {} }

function formatter.format(bufnr, opts)
    validate.opt_bufnr("number", bufnr)
    validate.opts("dict", opts)

    bufnr = bufnr or buffer.bufnr()
    opts = opts or {}
    local cmd = opts.cmd or opts[1]
    cmd = is_a.string(cmd) and cmd or cmd[1]
    if not cmd or dict.isdict(cmd) and dict.is_empty(cmd) then
        pp "no formatter found for buffer"
        return
    end

    bufnr = bufnr or buffer.bufnr()
    local stdin = opts.stdin
    local write = opts.write
    local append_filename = opts.append_filename
    local bufname = buffer.name(bufnr)

    if stdin then
        cmd = "cat " .. buffer.name(bufnr) .. " | " .. cmd
    elseif append_filename then
        cmd = cmd .. " " .. bufname
    end

    vim.cmd(":w! " .. bufname)
    buffer.setoption(bufnr, "modifiable", false)

    local winnr = buffer.winnr(bufnr)
    local view = winnr and win.saveview(winnr)
    local proc = process.new(cmd, {
        on_exit = function(proc)
            local bufnr = bufnr
            local name = bufname

            buffer.setoption(bufnr, "modifiable", true)

            if write then
                buffer.call(bufnr, function()
                    vim.cmd(":e! " .. bufname)
                    if view then win.restoreview(winnr, view) end
                end)

                return
            end

            local err = proc.stderr
            if not ((#err == 1 and #err[1] == 0) or #err == 0) then
                nvimerr(array.join(err, "\n"))
                return
            end

            local out = proc.stdout
            if #out == 0 then return end

            local bufnr = bufnr
            buffer.setlines(bufnr, 0, -1, out)

            if view then win.restoreview(winnr, view) end
        end,
    })

    local exists = formatter.formatter_processes[bufname]
    if exists then
        local userint = input {
            "userint",
            "Stop existing process for " .. bufname .. "? (y for yes)",
        }
        if userint.userint:match "y" then exists:stop() end
    end

    proc:start()

    return proc
end

return formatter
