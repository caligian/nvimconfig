require 'core.repl'
local repl = user.builtin.repl

user.builtin.kbd.noremap(
{'n', '<leader>xi', function ()
    local name = 'sh'
    local cmd = repl.commands[name]
    if not cmd then
        printf('No command defined for current buffer filetype %s', name)
    else
        repl.open_terminal(name, cmd)
        repl.split_terminal(name, 's')
    end
end, {desc = 'Start shell'}},
{'n', '<leader>xs', function ()
    local name = 'sh'
    if repl.is_running(name) then
        repl.split_terminal(name, 's')
    end
end, {desc = 'Split with shell window'}},
{'n', '<leader>xv', function ()
    local name = 'sh'
    if repl.is_running(name) then
        repl.split_terminal(name, 'v')
    end
end, {desc = 'Vsplit with shell window'}},
{'v', '<leader>xe', function ()
    local name = 'sh'
    local mode = vim.fn.mode()

    if repl.is_running(name) and mode == 'v' or mode == 'V' or mode == '' then
        repl.send_visual(name, 0)
    end
end, {desc = 'Send visual range to shell'}},
{'n', '<leader>xb', function ()
    local name = 'sh'
    if repl.is_running(name) then
        repl.send_buffer(name, 0)
    end
end, {desc = 'Send buffer to shell'}},
{'n', '<leader>x.', function ()
    local name = 'sh'
    if repl.is_running(name) then
        repl.send_till_point(name, 0)
    end
end, {desc = 'Send buffer till cursor to shell'}},
{'n', '<leader>xe', function ()
    local name = 'sh'
    if repl.is_running(name) then
        repl.send_current_line(name, 0)
    end
end, {desc = 'Send current line to shell'}},
{'n', '<leader>xq', function ()
    local name = 'sh'
    repl.stop_terminal(name)
end, {desc = 'Hide shell window'}},
{'n', '<leader>xk', function ()
    local name = 'sh'
    repl.hide_terminal(name)
end, {desc = 'Hide shell window'}})

user.builtin.kbd.noremap(
{'n', '<leader>ri', function ()
    local name = vim.bo.filetype
    local cmd = repl.commands[name]
    if not cmd then
        printf('No command defined for current buffer filetype %s', name)
    else
        repl.open_terminal(name, cmd)
        repl.split_terminal(name, 's')
    end
end, {desc = 'Start REPL for buffer'}},
{'n', '<leader>rs', function ()
    local name = vim.bo.filetype
    if repl.is_running(name) then
        repl.split_terminal(name, 's')
    end
end, {desc = 'Split with REPL window'}},
{'n', '<leader>rv', function ()
    local name = vim.bo.filetype
    if repl.is_running(name) then
        repl.split_terminal(name, 'v')
    end
end, {desc = 'Vsplit with REPL window'}},
{'v', '<leader>re', function ()
    local name = vim.bo.filetype
    local mode = vim.fn.mode()

    if repl.is_running(name) and mode == 'v' or mode == 'V' or mode == '' then
        repl.send_visual(name, 0)
    end
end, {desc = 'Send visual range to REPL'}},
{'n', '<leader>rb', function ()
    local name = vim.bo.filetype
    if repl.is_running(name) then
        repl.send_buffer(name, 0)
    end
end, {desc = 'Send buffer to REPL'}},
{'n', '<leader>r.', function ()
    local name = vim.bo.filetype
    if repl.is_running(name) then
        repl.send_till_point(name, 0)
    end
end, {desc = 'Send buffer till cursor to REPL'}},
{'n', '<leader>re', function ()
    local name = vim.bo.filetype
    if repl.is_running(name) then
        repl.send_current_line(name, 0)
    end
end, {desc = 'Send current line to REPL'}},
{'n', '<leader>rq', function ()
    local name = vim.bo.filetype
    repl.stop_terminal(name)
end, {desc = 'Hide REPL window'}},
{'n', '<leader>rk', function ()
    local name = vim.bo.filetype
    repl.hide_terminal(name)
end, {desc = 'Hide REPL window'}})
