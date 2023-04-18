local M = utils.telescope.create_actions_mod()
local Bookmark = require 'core.bookmarks.Bookmark'

local function get_fname(sel)
  return sel.cwd .. "/" .. sel[1]
end

function M.add_bookmark(sel)
  sel = get_fname(sel)
  if not Bookmark.get(sel) then Bookmark(sel) end
end

function M.remove_bookmark(sel)
  Bookmark.remove_path(get_fname(sel))
end

function M.delete(sel)
  local fname = get_fname(sel)
  print("rm -r " .. fname)
  print(vim.fn.system { "rm", "-r", fname })
end

return M
