local Bookmark = require "core.bookmarks.Bookmark"
-- user.bookmarks = user.bookmarks or state_module(Bookmark, 'BOOKMARK', {})
user.bookmarks = state_module(Bookmark, {})
local manager = user.bookmarks

manager.init_add(function(x)
  local state = manager.get_state()
  state[x.path] = x

  return x
end)

local name = vim.fn.bufname()
manager.add(vim.fn.bufname(), name)
pp(manager)
