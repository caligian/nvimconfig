local mod = {}
local action_state = require 'telescope.actions.state'
local actions = require 'telescope.actions'

function mod.bwipeout(bufnr)
    local sel = action_state.get_selected_entry()
    actions.close(bufnr)

    print('Wiping out buffer ' .. sel.bufnr)
    vim.cmd('bwipeout ' .. sel.bufnr)
end

function mod.nomodified(bufnr)
    local sel = action_state.get_selected_entry()
    actions.close(bufnr)

    print('Setting buffer status to nomodified: ' .. vim.fn.bufname(sel.bufnr))
    vim.api.nvim_buf_call(sel.bufnr, function() vim.cmd('set nomodified') end)
end

function mod.save(bufnr)
    local sel = action_state.get_selected_entry()
    actions.close(bufnr)

    print('Saving buffer ' .. sel.bufnr)
    local name = vim.fn.bufname(sel.bufnr)
    vim.cmd('w ' .. name)
end

function mod.readonly(bufnr)
    local sel = action_state.get_selected_entry()
    actions.close(bufnr)

    print('Setting buffer to readonly: ' .. vim.fn.bufname(sel.bufnr))
    vim.api.nvim_buf_call(sel.bufnr, function() vim.cmd('set nomodifiable') end)
end

return mod
