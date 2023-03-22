local function get_fname(f)
  return function(args)
    local fname = args.args
    if #fname == 0 then fname = vim.fn.expand "%:p" end
    fname = path.abspath(fname)
    f(fname)
  end
end

utils.command('BookmarkAdd', get_fname(Bookmarks.add), {nargs='?'})
utils.command('BookmarkRemove', get_fname(Bookmarks.remove), {nargs='?'})
utils.command('BookmarkSwitch', get_fname(Bookmarks.switch), {nargs='?'})
utils.command('BookmarkLoad', Bookmarks.load, {})
utils.command('BookmarkSave', Bookmarks.save, {})
utils.command('BookmarkShow', function ()
  pp(table.concat(table.map(table.keys(Bookmarks.bookmarks), function (x)
    return x:gsub(os.getenv('HOME'), '~')
  end), "\n"))
end, {})
