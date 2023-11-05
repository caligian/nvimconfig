require "core.utils.REPL"

REPL.map('n', 'r', 'start_and_split', 'split')
REPL.map('n', 's', 'start_and_split', 'split')
REPL.map('n', 'v', 'start_and_split', 'vsplit')
REPL.map('n', 'e', 'send_current_line')
REPL.map('n', '.', 'send_till_cursor')
REPL.map('n', 'b', 'send_buffer')
REPL.map('v', 'e', 'send_range')
REPL.map('n', 'k', 'hide')
REPL.map('n', 'q', 'stop')
kbd.map('n', '<leader>r!', ':lua REPL.stop_all()<CR>', {noremap = true})

autocmd.map('ExitPre', {
    pattern = '*',
    callback = function () REPL.stop_all() end
})
