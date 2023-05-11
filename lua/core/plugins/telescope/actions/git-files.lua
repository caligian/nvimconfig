local M = utils.telescope.create_actions_mod()
local B = require "core.utils.Bookmark"

local function get_fname(sel)
  return sel.cwd .. "/" .. sel[1]
end

function M.add_bookmark(sel)
  sel = get_fname(sel)
  if not Bookmark.get(sel) then
    Bookmark(sel)
  end
end

function M.remove_bookmark(sel)
  Bookmark.remove_path(get_fname(sel))
end

return M
