local function list_buffers()
  local buffers = table.grep(vim.fn.getbufinfo(), function(buf)
    local buftype = vim.api.nvim_buf_get_option(buf.bufnr, "buftype")
    if buftype == "nofile" or buf.listed == 0 or buf.loaded == 0 then 
      return false
    end
    if #buf.name == 0 then 
      return false 
    end

    return true
  end)

  return table.map(buffers, function(buf) return buf.name end)
end

local function list_bookmarks()
  return table.keys(Bookmarks.bookmarks)
end

utils.command("BookmarkRemove", function(args)
  for i=2,#args.fargs do
    args.fargs[i] = tonumber(args.fargs[i])
  end
  Bookmarks.remove(unpack(args.fargs))
end, { nargs = "+", complete = list_bookmarks })

utils.command("BookmarkAdd", function(args)
  table.ieach((args.fargs) )
  args.fargs[2] = tonumber(args.fargs[2])
  Bookmarks.add(unpack(args.fargs))
end, { nargs = "+", complete = list_buffers })

utils.command('BookmarkOpen', function (args)
  Bookmarks.jump(unpack(args.fargs))
end, {nargs=1, complete=list_bookmarks})

utils.command('BookmarkShow', function (args)
  local path = args.fargs[1]
  if path then
    table.each(Bookmarks.list(path), function (x)
      local linenum, context = unpack(x)
      print(sprintf('%-5d | %s', linenum, context))
    end)
  else
    table.each(Bookmarks.list(), print)
  end
end, {nargs='?', complete=list_bookmarks})

utils.command('BookmarkDelete', Bookmarks.delete, {})
utils.command('BookmarkSave', Bookmarks.save, {})
utils.command('BookmarkLoad', Bookmarks.load, {})
