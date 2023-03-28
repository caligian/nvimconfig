local function get_fname(f)
  return function(args)
    local fname = args.args
    if #fname == 0 then fname = vim.fn.expand "%:p" end
    fname = path.abspath(fname)
    f(fname)
  end
end

local function get_buffers()
  return table.grep(table.map(vim.fn.getbufinfo(), function (x)
    return x.name
  end), function (x)
    return not string.isblank(x)
  end)
end

local function get_bookmarks()
  return table.keys(Bookmarks.load())
end

utils.command('BookmarkAdd', get_fname(Bookmarks.add), {nargs='?', complete=get_buffers})
utils.command('BookmarkRemove', get_fname(Bookmarks.remove), {nargs='?', complete=get_bookmarks})
utils.command('BookmarkSwitch', get_fname(Bookmarks.switch), {nargs='?', complete=get_bookmarks})
utils.command('BookmarkLoad', Bookmarks.load, {})
utils.command('BookmarkSave', Bookmarks.save, {})
utils.command('BookmarkShow', function ()
  pp(table.concat(table.map(table.keys(Bookmarks.bookmarks), function (x)
    return x:gsub(os.getenv('HOME'), '~')
  end), "\n"))
end, {})

local function get_args(args)
  if args.args:isblank() then
    return false
  end
  return args.fargs
end

local function get_context(bufnr, line)
  bufnr = bufnr or vim.fn.bufnr()
  return {bufnr, line or vim.api.nvim_buf_call(bufnr, function ()
    return vim.fn.line('.') - 1
  end)}
end

local function list_marked_buffers()
  Marks.cleanup()
  return table.map(table.keys(Marks.marks), vim.fn.bufname)
end

local command = utils.command
command(
  'MarkAdd',
  function (args)
    args = get_args(args) or {}
    local buf, line = unpack(args)
    if is_a.s(buf) then
      if buf == '0' then
        buf = vim.fn.bufnr()
      else
        buf = vim.fn.bufnr(buf)
      end
    end
    Marks.add(unpack(get_context(buf, line)))
  end,
  {complete=get_buffers, nargs='?'}
)
