local enable = vim.api.nvim_create_autocmd
local disable = vim.api.nvim_del_autocmd
local getinfo = vim.api.nvim_get_autocmds
local create_augroup = vim.api.nvim_create_augroup

au = au
  or struct("au", {
    "id",
    "command",
    "name",
    "event",
    "pattern",
    "callback",
    "group",
    "once",
    "buffers",
    "buffer",
    "nested",
  })

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
  local found, msg = pcall(get, { group = self.group, event = self.event, buffer = self.buffers })

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
    dict.merge(all_groups, au.map_group(name, group, compile))
  end)

  return all_groups
end
