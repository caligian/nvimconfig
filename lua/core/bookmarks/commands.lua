local function list_buffers()
  local buffers = array.grep(vim.fn.getbufinfo(), function(buf)
    local buftype = vim.api.nvim_buf_get_option(buf.bufnr, "buftype")
    if buftype == "nofile" or buf.listed == 0 or buf.loaded == 0 then
      return false
    end
    if #buf.name == 0 then
      return false
    end

    return true
  end)

  return array.map(buffers, function(buf)
    return buf.name
  end)
end

local function list_bookmarks()
  return dict.keys(Bookmarks.bookmarks)
end

utils.command("BookmarksAddCurrent", function(args)
  local line = args.args[1]
  line = line or "."
  if line ~= "." then
    line = tonumber(line)
  end
  Bookmarks.add(vim.api.nvim_buf_get_name(vim.fn.bufnr()), line)
end, { nargs = "?" })

utils.command("BookmarksRemoveCurrent", function(args)
  local line = args.args[1]
  line = line or "."
  if line ~= "." then
    line = tonumber(line)
  end
  Bookmarks.remove(vim.api.nvim_buf_get_name(vim.fn.bufnr()), line)
end, {
  nargs = "?",
  complete = function()
    local name = vim.api.nvim_buf_get_name(vim.fn.bufnr())
    if not Bookmarks.exists(name) then
      return {}
    end
    return dict.keys(Bookmarks.exists(name))
  end,
})

utils.command("BookmarksRemove", function(args)
  for i = 2, #args.fargs do
    args.fargs[i] = tonumber(args.fargs[i])
  end
  Bookmarks.remove(unpack(args.fargs))
end, { nargs = "+", complete = list_bookmarks })

utils.command("BookmarksAdd", function(args)
  local fname = args.fargs[1]
  if fname == "%" then
    fname = vim.fn.expand "%:p"
  end
  local s_args = array.map(array.rest(args.fargs), function(x)
    if x == "." then
      return x
    end
    return tonumber(x)
  end)
  Bookmarks.add(fname, unpack(s_args))
end, { nargs = "+", complete = list_buffers })

utils.command("BookmarksOpen", function(args)
  Bookmarks.jump(unpack(args.fargs))
end, { nargs = 1, complete = list_bookmarks })

utils.command("BookmarksShow", function(args)
  local p = args.fargs[1] or vim.api.nvim_buf_get_name(vim.fn.bufnr())
  if p then
    local ls = Bookmarks.list(p)
    if ls then
      dict.each(Bookmarks.list(p), function(k, x)
        print(sprintf("%-5d | %s", k, x))
      end)
    end
  else
    local ls = Bookmarks.list(p)
    if ls then
      array.each(ls, print)
    end
  end
end, { nargs = "?", complete = list_bookmarks })

utils.command("BookmarksDelete", Bookmarks.delete_all, {})
utils.command("BookmarksSave", Bookmarks.save, {})
utils.command("BookmarksLoad", Bookmarks.load, {})
