builtin.require('core.globals')
builtin.require('core.option')
builtin.require('core.autocmd')
builtin.require('core.kbd')
builtin.require('core.pkg')
builtin.require('core.kbd.defaults')
builtin.require("core.autocmd.defaults")
builtin.require("core.repl")
builtin.require('core.repl.commands')
builtin.require('core.repl.keybindings')

vim.api.nvim_create_user_command('ShowLogs', function()
    local all_logs = {}
    for _, log in ipairs(builtin.logs) do
        log = vim.split(log, "\n")
        for _, s in ipairs(log) do
            builtin.append(all_logs, s)
        end
    end

    local log_buffer = vim.fn.bufadd('startup_log')
    local bufnr = vim.fn.bufnr(log_buffer)
    vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, all_logs)

    vim.cmd('b startup_log')
end, {})
