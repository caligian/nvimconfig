require 'core.bufgroups.BufGroup'

utils.telescope.load()

local _ = utils.telescope
local mod = _.create_actions_mod()

function mod.add(sel)
  vim.fn.input('')
end
