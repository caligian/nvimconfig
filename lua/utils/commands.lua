-- For logs
vim.api.nvim_create_user_command('ShowLogs', function()
    local all_logs = {}
    for _, log in ipairs(V.logs) do
        log = vim.split(log, "\n")
        for _, s in ipairs(log) do
            V.append(all_logs, s)
        end
    end
    if vim.fn.bufexists('startup_log') == 0 then
        vim.fn.bufadd('startup_log')
    end
    local bufnr = vim.fn.bufnr('startup_log')
    vim.api.nvim_buf_set_option(bufnr, 'buflisted', true)
    vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, all_logs)

    vim.keymap.set({ 'n', 'i' }, 'q', ':bprev | bdelete ' .. bufnr .. '<CR>', { buffer = bufnr })

    vim.cmd('b startup_log')
end, {})

vim.cmd('noremap <space>hl :ShowLogs<CR>')

-- Buffer utils
vim.api.nvim_create_user_command('OpenScratch', function() Buffer.open_scratch() end, {})
vim.api.nvim_create_user_command('OpenScratchVertically', function() Buffer.open_scratch(false, 'v') end, {})
vim.keymap.set('n', ',%', '<cmd>OpenScratch<CR>', { noremap = true })
vim.keymap.set('n', ',|', '<cmd>OpenScratchVertically<CR>', { noremap = true })
