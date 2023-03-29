local M = utils.telescope.create_actions_mod()
local B = Bookmarks
local Bpicker = require 'core.plugins.telescope.bookmarks-picker'

local function get_fname(sel)
  return sel.cwd .. '/' .. sel[1]
end

function M.add_bookmark(sel)
  B.add(get_fname(sel))
end

function M.remove_bookmark(sel)
  local fname = get_fname(sel)
  if not B.bookmarks[fname] then
    return
  end
  Bpicker.get_linenum_remover(get_fname(sel))
end

return M
