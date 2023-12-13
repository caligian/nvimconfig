local enable = vim.api.nvim_create_autocmd
local disable = vim.api.nvim_del_autocmd
local getinfo = vim.api.nvim_get_autocmds
local create_augroup = vim.api.nvim_create_augroup

if not au then
  au = class "au"
  au.autocmds = {}
end

au.autocmds = au.autocmds or {}

function au.init(self, event, opts)
  local pattern = opts.pattern
  local callback = opts.callback
  local group = opts.group or "MyGroup"
  local buffers = {}
  local name = opts.name
  local cb = opts.callback
  local callback
  local once = opts.once
  local nested = opts.nested
  local command = opts.command
  local desc = opts.desc
  local buf = opts.buffer

  assert(cb or command, "expected command or callback")

  if not command then
    function callback(opts)
      cb(opts)
      list.append(buffers, buffer.bufnr())
    end
  end

  self.event = event
  self.pattern = pattern
  self.group = group
  self.name = name
  self.callback = callback
  self.command = command
  self.buffer = buf

  opts = {
    pattern = pattern,
    command = command,
    callback = callback,
    nested = nested,
    once = once,
    group = group,
    desc = desc,
    buffer = buf,
  }

  if group then
    create_augroup(group, { clear = false })
  end

  self.id = enable(event, opts)

  if name then
    if group then
      name = group .. "." .. name
    end

    au.autocmds[name] = self
  end

  return self
end

function au.exists(self)
  local found, msg = pcall(get, {
    group = self.group,
    event = self.event,
    buffer = self.buffers,
  })

  if not found then
    if msg and msg:match "Invalid .group." then
      create_augroup(self.group, {})
    end

    return
  end

  found = msg
  found = list.each(found, function(x)
    return self.id and x.id == self.id
  end)

  if #found > 0 then
    return self
  end
end

function au.enable(self)
  if au.exists(self) then
    return self.id
  end

  self.id = enable(self.event, {
    pattern = self.pattern,
    group = self.group,
    callback = self.callback,
    once = self.once,
    nested = self.nested,
  })

  return id
end

function au.disable(self)
  if not au.exists(self) then
    return
  end

  return disable(self.id)
end

function au.find(spec)
  return getinfo(spec)
end

function au.map(...)
  local x = au(...)
  local id = au.enable(x)

  return x, id
end

function au.map_group(group, mappings, compile)
  local opts = mappings.opts
  local apply = mappings.apply
  local mapped = {}

  dict.each(mappings, function(key, value)
    if key == "opts" or key == "apply" then
      return
    end

    value = deepcopy(value)

    local event, rest
    local event, rest = unpack(value)
    local name = group .. "." .. key
    rest.group = group

    if opts then
      rest = dict.merge(copy(rest), opts)
    end

    rest.name = name

    if apply then
      event, rest = apply(event, rest)
    end

    if compile then
      mapped[name] = au(event, rest)
    else
      mapped[name] = au.map(event, rest)
    end
  end)

  return mapped
end

function au.map_groups(groups, compile)
  local all_groups = {}

  dict.map(groups, function(name, group)
    dict.merge(
      all_groups,
      au.map_group(name, group, compile)
    )
  end)

  return all_groups
end

function au.fromdict(specs)
  assertisa(specs, function(x)
    return dict.isa(x, function(arg)
      return islist(arg)
        and #arg == 2
        and isdict(arg[2])
        and arg[2].callback
        and arg[2].pattern
    end)
  end)

  local out = {}
  for key, value in pairs(specs) do
    params {
      {
        {
          union("string", "table"),
          {
            __extra = true,
            callback = union("string", "callable"),
            pattern = union("string", "table"),
          },
        },
        value,
      },
    }

    value[2] = isstring(value[2]) and { desc = value[2] }
      or value[2]
    value[2].name = key

    out[key] = au.map(unpack(value))
  end

  return out
end

function au.loadfile()
  local src = req2path "core.defaults.autocmds"
  local usersrc = req2path "user.autocmds"
  local specs = {}

  if src then
    local config = loadfile(src)
    if isfunction(config) then
      config = config()
      if istable(config) then
        dict.merge(specs, config)
      end
    end
  end

  if usersrc then
    local config = loadfile(usersrc)
    if isfunction(config) then
      config = config()
      if istable(config) then
        dict.merge(specs, config)
      end
    end
  end

  return au.fromdict(specs)
end

function au.require()
  local src = req2path "core.defaults.autocmds"
  local usersrc = req2path "user.autocmds"
  local specs = {}

  if usersrc then
    local config = requirex "core.defaults.autocmds"
    if istable(config) then
      dict.merge(specs, config)
    end
  end

  if src then
    local config = requirex "core.defaults.autocmds"
    if istable(config) then
      dict.merge(specs, config)
    end
  end

  return au.fromdict(specs)
end

function au.main()
  return au.require()
end
