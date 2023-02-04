local function compile_and_run(lines)
    if V.is_type(lines, 'table') then
        lines = table.concat(lines, "\n")
    end

    local compiled, err = loadstring(lines)
    if err then
        V.nvim_err(err)
    elseif compiled then
        compiled()
    end
end

-- Setup commands
vim.api.nvim_create_user_command('NvimEvalRegion', function()
    local lines = V.get_visual_range()
    compile_and_run(lines)
end, { range = true })

vim.api.nvim_create_user_command('NvimEvalBuffer', function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    compile_and_run(lines)
end, {})

vim.api.nvim_create_user_command('NvimEvalTillPoint', function()
    local line = vim.fn.line('.')
    local lines = vim.api.nvim_buf_get_lines(0, 0, line - 1, false)
    compile_and_run(lines)
end, {})

vim.api.nvim_create_user_command('NvimEvalLine', function()
    local line = vim.fn.getline('.')
    compile_and_run(line)
end, {})


-- Setup keybindings
Keybinding.noremap('v', '<leader><leader>', '<esc><cmd>NvimEvalRegion<CR>', { desc = 'Lua source range' })

Keybinding({
    silent = true,
    noremap = true,
    leader = true,
}):bind {
    { '<leader>', '<cmd>NvimEvalLine<CR>', { desc = 'Lua source line' } },
    { 'ee', '<cmd>NvimEvalLine<CR>', { desc = 'Lua source line' } },
    { 'eb', '<cmd>NvimEvalBuffer<CR>', { desc = 'Lua source buffer' } },
    { 'e.', '<cmd>NvimEvalTillPoint<CR>', { desc = 'Lua source till point' } }
}
