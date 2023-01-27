local action_state = require 'telescope.actions.state'
local actions = require 'telescope.actions'
local job = require 'plenary.job'
local mod = {}

function mod.delete_recursively(prompt_bufnr)
    local selected = action_state.get_selected_entry()
    local path = selected[1]
    local cwd = selected.cwd

    job:new({ command = '/sbin/rm', args = {'-r', path}, cwd=cwd}):start()

    print('Attempting to delete ' .. path)
    actions.close(prompt_bufnr)
end

function mod.luafile(bufnr)
    local sel = action_state.get_selected_entry()
    local path = sel[1]

    vim.cmd('luafile ' .. path)

    print('Sourced lua file ' .. path)
    actions.close(bufnr)
end

function mod.git_init(bufnr)
    local sel = action_state.get_selected_entry()
    local cwd = sel.cwd

    job:new({command='/usr/bin/git', args={'init'}, cwd=cwd}):start()

    actions.close(bufnr)
end

function mod.open_in_netrw(bufnr)
    local sel = action_state.get_selected_entry()
    local cwd = sel.cwd

    vim.cmd('Ntree ' .. cwd)

    actions.close(bufnr)
end

return mod
