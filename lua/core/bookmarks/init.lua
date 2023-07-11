require "core.Bookmark"
require "core.bookmarks.kbd"

if user.bookmark.load_on_open then
  vim.cmd ":BookmarkLoad"
end

if user.bookmark.save_on_exit and not user.autocmd.save_bookmarks_on_exit then
  Autocmd("QuitPre", {
    pattern = "*",
    callback = ":BookmarkSave",
  })
end
