V.makepath(user, 'buffer', 'scratch')
user.buffer.scratch.name = path.join(vim.fn.stdpath('config'), 'tmp', 'scratch_buffer')
user.buffer.scratch.bufnr = vim.fn.bufadd(user.buffer.scratch.name)
user.buffer.scratch.bufname = vim.fn.bufname(user.buffer.scratch.bufnr)
local bufname = user.buffer.scratch.name
local bufnr = user.buffer.scratch.bufnr

local function ensure_buffer()
    if vim.fn.bufexists(bufnr) == 0 then
        user.buffer.scratch.bufnr = vim.fn.bufadd(user.buffer.scratch.name)
        bufnr = user.buffer.scratch.bufnr
        user.buffer.scratch.bufname = vim.fn.bufname(bufnr)
        bufname = user.buffer.scratch.bufname
    end
end

local function open_scratch_buffer(split)
    ensure_buffer()

    if vim.fn.bufwinid(bufname) ~= -1 then
        local bufwinid = vim.fn.bufwinid(bufnr)
        vim.fn.win_gotoid(bufwinid)

        return
    end

    split = split or 's'
    if split == 's' then
        vim.cmd('split | wincmd j | b ' .. bufnr)
    elseif split == 'v' then
        vim.cmd('vsplit | wincmd l | b ' .. bufnr)
    elseif split == 't' then
        vim.cmd('tabnew b ' .. bufnr)
    elseif split == 'b' then
        vim.cmd('b ' .. bufnr)
    end
end

function hide_scratch_buffer()
    local winid = vim.fn.bufwinid(bufnr)
    if winid == -1 then
        return
    end

    vim.fn.win_gotoid(winid)
    vim.cmd('hide')
end

vim.api.nvim_create_user_command('GotoScratchBuffer', V.partial(open_scratch_buffer, 'b'), {})
vim.api.nvim_create_user_command('SplitScratchBuffer', V.partial(open_scratch_buffer, 's'), {})
vim.api.nvim_create_user_command('VsplitScratchBuffer', V.partial(open_scratch_buffer, 'v'), {})
vim.api.nvim_create_user_command('TabScratchBuffer', V.partial(open_scratch_buffer, 't'), {})
vim.api.nvim_create_user_command('HideScratchBuffer', hide_scratch_buffer, {})

Keybinding({
    silent = true,
    noremap = true,
    localleader = true,
}):bind {
    { ',,', '<cmd>SplitScratchBuffer<CR>' },
    { ',v', '<cmd>VsplitScratchBuffer<CR>' },
    { ',s', '<cmd>SplitScratchBuffer<CR>' },
    { ',b', '<cmd>GotoScratchBuffer<CR>' },
    { ',t', '<cmd>GotoScratchBuffer<CR>' },
    { ',k', '<cmd>HideScratchBuffer<CR>' },
}
