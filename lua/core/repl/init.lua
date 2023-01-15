get(user.builtin.repl, 'ids', true)
get(user.builtin.repl, 'buffers', true)
update(user.builtin.repl, {'commands'}, {
    python = 'ipython3 -q',
    ruby = 'irb --inf-ruby-mode',
    lua = 'lua5.1',
    sh = 'zsh',
})
user.config.repl = user.config.repl or {}
local repl = user.builtin.repl
merge(repl, user.config.repl)

function repl.is_visible(id)
    local winnr = vim.fn.bufwinnr(repl.ids[id].buffer)
    return winnr ~= -1
end

function repl.status(id)
    if type(id) == 'string'  then
        id = repl.ids[id].id
    end

    id = vim.fn.jobwait({id}, 0)[1]
    if id == -1 then
        return 'running'
    elseif id == -2 then
        return 'interrupted'
    else
        return false
    end
end

function repl.is_valid(id)
    return not repl.status(id)
end

function repl.is_running(id)
    return repl.status(id) == 'running'
end

function repl.is_interrupted(id)
    return repl.status(id) == 'interrupted'
end

function repl.stop_terminal(id)
    if not repl.is_running(id) then return end
    local r = repl.ids[id]
    id = r.id
    vim.fn.chanclose(id)
    r.running = false
    repl.hide_terminal(id)

    if vim.fn.bufexists(r.buffer) == 1 then
        vim.api.nvim_buf_delete(r.buffer, {force=true})
    end
end

function repl.stop_all_terminals()
    for _, r in pairs(repl.buffers) do
        repl.stop_terminal(r.id)
    end
end


function repl.open_terminal(opts)
    opts = opts or {}
    opts.name = opts.name or vim.bo.filetype
    opts.cmd = opts.cmd or repl.commands[opts.name]
    local name, cmd = opts.name, opts.cmd

    assert(cmd, 'No command provided')

    if repl.ids[name] and repl.ids[name].running then
        return repl.ids[name]
    end

    local current_buf = vim.fn.bufnr(0)
    local buf = vim.api.nvim_create_buf(false, true)
    local id = nil

    vim.api.nvim_buf_call(buf, function ()
        vim.cmd('term')
        id = vim.b.terminal_job_id
        vim.bo.buflisted = false
        vim.wo.number = false
        vim.cmd('set nomodified')
        vim.api.nvim_chan_send(id, cmd .. "\r")
    end)

    local r = {
        id = id,
        running = true,
        command = cmd,
        buffer = buf,
        name = name,
    }
    repl.ids[id] = r
    repl.ids[name] = r
    repl.buffers[buf] = r

    return r
end

function repl.split_terminal(id, direction)
    if (not repl.is_running(id)) or repl.is_visible(id) then
        return
    end

    direction = direction or 's'
    local terminal_buf = repl.ids[id].buffer
    if direction == 's' then
        local height = vim.fn.winheight(0) / 3
        local count = math.floor(height)
        vim.cmd('split | wincmd j | b ' .. terminal_buf .. ' | resize ' .. count)
    else
        local width = vim.fn.winwidth(0) / 3
        local count = math.floor(width)
        vim.cmd('vsplit | wincmd l | b ' .. terminal_buf .. ' | vertical resize ' .. count)
    end
end

function repl.hide_terminal(id)
    if not repl.is_visible(id) then
        return
    end

    local buf = repl.ids[id].buffer
    vim.api.nvim_buf_call(buf, function ()
        local winid = vim.fn.bufwinid(buf)
        vim.fn.win_gotoid(winid)
        vim.cmd('hide')
    end)
end

function repl.send_string(id, s)
    if not repl.is_running(id) then return end

    id = repl.ids[id].id
    if is_type(s, 'table')  then
        s = table.concat(s, "\n")
    end
    s = s .. "\r"
    vim.api.nvim_chan_send(id, s)
end

function repl.send_current_line(id, buf)
    if not repl.is_running(id) then return end

    vim.api.nvim_buf_call(buf, function()
        repl.send_string(id, vim.fn.getline('.'))
    end)
end

function repl.send_buffer(id, buf)
    if not repl.is_running(id) then return end

    vim.api.nvim_buf_call(buf, function()
        repl.send_string(id, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    end)
end

function repl.send_till_point(id, buf)
    if not repl.is_running(id) then return end

    vim.api.nvim_buf_call(buf, function()
        local line = vim.fn.line('.')
        repl.send_string(id, vim.api.nvim_buf_get_lines(buf, 0, line, false))
    end)
end

function repl.send_visual(id, buf)
    if not repl.is_running(id) then return end

    vim.api.nvim_buf_call(buf, function ()
        if vim.fn.mode() ~= 'v' then
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")
            repl.send_string(id, vim.api.nvim_buf_get_text(buf, start_pos[2]-1, start_pos[3]-1, end_pos[2]-1, end_pos[3], {}))
        end
    end)
end

return repl
