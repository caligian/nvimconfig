local action_state = require 'telescope.actions.state'
local actions = require 'telescope.actions'
local mod = {}

setmetatable(mod, {
    __newindex = function (self, k, v)
        rawset(self, k, function (bufnr)
            local sel = action_state.get_selected_entry()
            v(sel)
            actions.close(bufnr)
        end)
    end
})

function mod.bwipeout(sel)
    print('Wiping out buffer ' .. sel.bufnr)
    vim.cmd('bwipeout ' .. sel.bufnr)
end

function mod.create(sel)
end

require('telescope').setup {
    pickers = {
        buffers = {
            mappings = {
                n = {
                    ['<C-s>'] = mod.bwipeout,
                }
            }
        }
    }
}
