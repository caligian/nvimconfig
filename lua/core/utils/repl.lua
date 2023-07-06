require "core.utils.filetype"
require "core.utils.terminal"

repl = repl
    or {
        repls = {},
        single_repls = {},
        exception = {
            no_command = exception "no command provided",
            no_filetype = exception "no filetype provided",
        },
    }

function repl.get_command(ft)
    if is_a.number(ft) then 
        ft = buffer.call(ft, "filetype") 
        if #ft == 0 then return end
    end
     
    local cmd, opts
    cmd = filetype.get(ft, 'repl')

    if is_a.table(cmd) then
        opts = deepcopy(cmd)
        cmd = opts[1]
        opts[1] = nil
    end

    return cmd, opts
end

function repl.exists(bufnr_or_filetype, callback)
    local found
    if is_a.string(bufnr_or_filetype) then
        found = repl.single_repls[bufnr_or_filetype]
    else
        found = repl.repls[bufnr_or_filetype]
    end

    if found then
        if callback then return callback(found) end
        return found
    end

    return false
end

function repl.if_running(bufnr_or_filetype, on_success, on_failure)
    local found
    if is_a.string(bufnr_or_filetype) then
        found = repl.single_repls[bufnr_or_filetype]
    else
        found = repl.repls[bufnr_or_filetype]
    end

    if not found or not found:is_running(80) then
        if on_failure then return on_failure(bufnr_or_filetype) end
    elseif on_success then
        return on_success(found)
    else
        return found
    end
end

function repl.start(bufnr_or_filetype, opts)
    local x = repl.new(bufnr_or_filetype, opts)
    if not x then return end

    return x:start()
end

function repl.stop(bufnr_or_filetype)
    return repl.if_running(bufnr_or_filetype, function(x) x:stop() end)
end

function repl.stop_all()
    dict.each(repl.repls, function(bufnr, x) x:stop() end)
    dict.each(repl.single_repls, function(bufnr, x) x:stop() end)
end

function repl.new(bufnr, opts)
    opts = deepcopy(opts or {})

    local function buffer_start()
        if not buffer.exists(bufnr) then error "invalid_buffer" end

        local ft = buffer.option(bufnr, "filetype")
        if #ft == 0 then error "invalid_filetype" end

        local cmd, _opts = opts.cmd, nil
        if not cmd then
            cmd, _opts = repl.get_command(ft)
            if _opts then dict.merge(opts, _opts) end
        end

        local exists = repl.exists(bufnr)
        if exists and exists:is_running() then return exists end

        local rest = opts.opts
        local x = terminal.new(cmd, rest)

        x.filetype = ft
        x.buffer = bufnr

        repl.repls[bufnr] = x

        x:start()

        return x
    end

    local function filetype_start()
        local rest = opts.opts
        local ft = bufnr
        local cmd, _opts = repl.get_command(ft)

        if not cmd then error "no_command" end

        if _opts then dict.merge(opts, _opts) end

        local exists = repl.exists(ft)
        if exists and exists:is_running() then return exists end

        local x = terminal.new(cmd, opts)
        repl.single_repls[ft] = x

        x:start()

        return x
    end

    if is_a.string(bufnr) then
        return filetype_start()
    else
        return buffer_start()
    end
end

function repl.float(bufnr, opts)
    return repl.if_running(bufnr, function(x) x:float(opts) end)
end

function repl.split(bufnr, direction)
    return repl.if_runnnig(bufnr, function(x) x:split(direction) end)
end

function repl.map_commands(commands)
    repl.command_group = command_group.new "repl"

    dict.each(
        commands or repl.commands,
        function(name, spec) repl.command_group:add(name, unpack(spec)) end
    )

    return repl.command_group
end

function repl.load_mappings(mappings)
    mappings = mappings or repl.mappings
    kbd.map_group('repl', repl.mappings)
end
