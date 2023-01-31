local function compile_and_run(lines)
    if builtin.is_type(lines, 'table') then
        lines = table.concat(lines, "\n")
    end

    local compiled, err = loadstring(lines)
    if err then
        builtin.nvim_err(err)
    else
        compiled()
    end
end

vim.api.nvim_create_user_command('NvimEvalRegion', function()
    local lines = builtin.get_visual_range()
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

user.kbd.noremap(
    { 'v', '<leader><leader>', '<esc><cmd>NvimEvalRegion<CR>', { desc = 'Lua source range' } },
    { 'n', '<leader><leader>', '<cmd>NvimEvalLine<CR>', { desc = 'Lua source line' } },
    { 'n', '<leader>ee', '<cmd>NvimEvalLine<CR>', { desc = 'Lua source line' } },
    { 'n', '<leader>eb', '<cmd>NvimEvalBuffer<CR>', { desc = 'Lua source buffer' } },
    { 'n', '<leader>e.', '<cmd>NvimEvalTillPoint<CR>', { desc = 'Lua source till point' } })
