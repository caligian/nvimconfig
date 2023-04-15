local function get_bufgroups()
  local groups = table.keys(Bufgroup.BUFGROUPS) 
  table.sort(groups)
  return groups
end

local function get_first(args)
  return args.fargs[1]
end

utils.command(
  'GroupCurrentBufferSelect',
  function ()
    local picker = BufgroupPool.create_picker_for_buffer(vim.fn.bufnr())
    if picker then
      picker:find()
    end
  end
)

utils.command(
  'GroupShowAll',
  function ()
    local ks = table.keys(Bufgroup.BUFGROUPS)
    if #ks == 0 then return end
    table.sort(ks)
    array.each(ks, print)
  end
)

utils.command(
  'GroupShow',
  function (args)
    local arg = get_first(args)
    if not arg then return end
    local group = Bufgroup.BUFGROUPS[arg]
    local picker = group:create_picker()
    if picker then picker:find() end
  end,
  {
    nargs = 1,
    complete = get_bufgroups
  }
)
utils.command(
  'GroupSelectAll',
  function ()
    local picker = Bufgroup.create_main_picker()
    if picker then picker:find() end
  end
)

utils.command(
  'GroupSelect',
  function (args)
    local arg = get_first(args)
    if not arg then return end
    local group = Bufgroup.BUFGROUPS[arg]
    if not group then return end
    local picker = group:create_picker()
    if picker then picker:find() end
  end,
  {
    nargs = 1,
    complete = get_bufgroups
  }
)
