local Bookmark = require 'core.bookmarks.Bookmark'
local list_buffers = Bookmark.list_buffers
local list_bookmarks = function () return dict.keys(Bookmark.list_all()) end

local function args2number(args)
  return array.map(args, tonumber)
end

utils.command('BookmarkRemovePicker', function (args)
  local arg = args.fargs[1]
  if not arg then
    local picker = Bookmark.create_main_picker(true)
    if picker then picker:find() end
  else
    local exists = Bookmark.get(arg)
    if exists then
      local picker = exists:create_picker(true)
      if picker then picker:find() end
    end
  end
end, { complete = list_bookmarks, nargs = '?' })

utils.command('BookmarkPicker', function (args)
  local arg = args.fargs[1]
  if not arg then
    local picker = Bookmark.create_main_picker()
    if picker then picker:find() end
  else
    local exists = Bookmark.get(arg)
    if exists then
      local picker = exists:create_picker()
      if picker then picker:find() end
    end
  end
end, { complete = list_bookmarks, nargs = '?' })

utils.command('BookmarkCurrentBufferPicker', function ()
  local picker = Bookmark.create_current_buffer_picker()
  if picker then picker:find() end
end, {})

utils.command('BookmarkRemoveCurrentBufferPicker', function ()
  local picker = Bookmark.create_current_buffer_picker(true)
  if picker then picker:find() end
end, {})

utils.command('BookmarkToggleLine', function (args)
  local line = tonumber(args.fargs[1]) or vim.fn.line('.')
  local bufnr = vim.fn.bufnr()
  if not Bookmark.get(bufnr, line) then
    Bookmark.add_line(bufnr, line)
  else
    Bookmark.remove_line(bufnr, line)
  end
end)

utils.command('BookmarkRemoveLine', function (args)
  args = args.fargs
  if #args == 0 then
    Bookmark.add_current_buffer(vim.fn.line('.'))
  else
    array.each(Bookmark.remove_current_buffer, args2number(args))
  end
end)

utils.command('BookmarkLine', function (args)
  args = args.fargs
  if #args == 0 then
    Bookmark.add_current_buffer(vim.fn.line('.'))
  else
    array.each(Bookmark.add_current_buffer, args2number(args))
  end
end)

utils.command("BookmarkCurrentBuffer", function(args)
  local line = args.args[1]
  line = line or "."
  if line ~= "." then line = tonumber(line) end
  Bookmark.add_current_buffer(line)
end, { nargs = "?" })

utils.command("BookmarkRemoveCurrentBuffer", function(args)
  local line = args.args[1]
  line = line or "."
  if line ~= "." then line = tonumber(line) end
  Bookmark.remove_current_buffer(line)
end, {
  nargs = "?",
  complete = function()
    local name = vim.api.nvim_buf_get_name(vim.fn.bufnr())
    if not Bookmark.exists(name) then
      return {}
    end
    return dict.keys(Bookmark.exists(name))
  end,
})

utils.command("BookmarkRemove", function(args)
  local fname = args.fargs[1]
  for i = 2, #args.fargs do
    local line = tonumber(args.fargs[i])
    Bookmark.remove_line(fname, line)
  end
end, { nargs = "+", complete = list_bookmarks })

utils.command("BookmarkAdd", function(args)
  local fname = args.fargs[1]
  for i = 2, #args.fargs do
    local line = tonumber(args.fargs[i])
    Bookmark.add_line(fname, line)
  end
end, { nargs = "+", complete = list_buffers })

utils.command("BookmarkOpen", function(args)
  Bookmark.jump_to_line(unpack(args.fargs))
end, { nargs = '+', complete = list_bookmarks })

utils.command("BookmarkShow", function(args)
  local p = args.fargs[1]
  if not p then
    Bookmark.print_all() 
  else
    local obj = Bookmark.get(p)
    if obj then obj:print() end
  end
end, { nargs = "?", complete = list_bookmarks })

utils.command("BookmarkSave", Bookmark.save, {})
utils.command("BookmarkLoad", Bookmark.load, {})
utils.command("BookmarkReset",Bookmark.reset, {})
