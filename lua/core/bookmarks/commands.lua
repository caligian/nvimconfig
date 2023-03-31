local function list_buffers()
  local buffers = table.grep(vim.fn.getbufinfo(), function(buf)
    local buftype = vim.api.nvim_buf_get_option(buf.bufnr, "buftype")
    if buftype == "nofile" or buf.listed == 0 or buf.loaded == 0 then
      return false
    end
    if #buf.name == 0 then return false end

    return true
  end)

  return table.map(buffers, function(buf) return buf.name end)
end

local function list_bookmarks() return table.keys(Bookmarks.bookmarks) end

utils.command("BookmarksRemove", function(args)
  for i = 2, #args.fargs do
    args.fargs[i] = tonumber(args.fargs[i])
  end
  Bookmarks.remove(unpack(args.fargs))
end, { nargs = "+", complete = list_bookmarks })

utils.command("BookmarksAdd", function(args)
  local fname = args.fargs[1]
  if fname == "%" then fname = vim.fn.expand "%:p" end
  local s_args = table.map(table.rest(args.fargs), function(x)
    if x == "." then return x end
    return tonumber(x)
  end)
  Bookmarks.add(fname, unpack(s_args))
end, { nargs = "+", complete = list_buffers })

utils.command(
  "BookmarksOpen",
  function(args) Bookmarks.jump(unpack(args.fargs)) end,
  { nargs = 1, complete = list_bookmarks }
)

utils.command("BookmarksShow", function(args)
  local path = args.fargs[1]
  if path then
    table.each(Bookmarks.list(path), function(x)
      local linenum, context = unpack(x)
      print(sprintf("%-5d | %s", linenum, context))
    end)
  else
    table.each(Bookmarks.list(), print)
  end
end, { nargs = "?", complete = list_bookmarks })

utils.command("BookmarksDelete", Bookmarks.delete_all, {})
utils.command("BookmarksSave", Bookmarks.save, {})
utils.command("BookmarksLoad", Bookmarks.load, {})
