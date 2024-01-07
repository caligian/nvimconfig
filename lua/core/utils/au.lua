local enable = vim.api.nvim_create_autocmd
local disable = vim.api.nvim_del_autocmd
local getinfo = vim.api.nvim_get_autocmds
local create_augroup = vim.api.nvim_create_augroup

if not Autocmd then
  Autocmd = class "Autocmd"
  user.autocmds = {}
end

function Autocmd.init(self, event, opts)
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
      list.append(buffers, { Buffer.bufnr() })
    end
  end

  self.map = nil
  self.fromdict = nil
  self.require = nil
  self.loadfile = nil
  self.main = nil
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

    user.autocmds[name] = self
  end

  return self
end

function Autocmd.exists(self)
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

function Autocmd.enable(self)
  if Autocmd.exists(self) then
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

function Autocmd.disable(self)
  if not Autocmd.exists(self) then
    return
  end

  return disable(self.id)
end

function Autocmd.find(spec)
  return getinfo(spec)
end

function Autocmd.map(...)
  local x = Autocmd(...)
  local id = Autocmd.enable(x)

  return x, id
end

function Autocmd.fromdict(specs)
  assertisa(specs, function(x)
    return dict.is_a(x, function(arg)
      return is_list(arg) and #arg == 2 and is_dict(arg[2]) and arg[2].callback and arg[2].pattern
    end)
  end)

  local out = {}
  for key, value in pairs(specs) do
    value[2] = is_string(value[2]) and { desc = value[2] } or value[2]
    value[2].name = key

    out[key] = Autocmd.map(unpack(value))
  end

  return out
end

function Autocmd.loadfile()
  local src = req2path "core.defaults.autocmds"
  local usersrc = req2path "user.autocmds"
  local specs = {}

  if src then
    local config = loadfile(src)
    if is_function(config) then
      config = config()
      if is_table(config) then
        dict.merge(specs, { config })
      end
    end
  end

  if usersrc then
    local config = loadfile(usersrc)
    if is_function(config) then
      config = config()
      if is_table(config) then
        dict.merge(specs, { config })
      end
    end
  end

  return Autocmd.fromdict(specs)
end

function Autocmd.require()
  local src = req2path "core.defaults.autocmds"
  local usersrc = req2path "user.autocmds"
  local specs = {}

  if usersrc then
    local config = requirex "core.defaults.autocmds"
    if is_table(config) then
      dict.merge(specs, { config })
    end
  end

  if src then
    local config = requirex "core.defaults.autocmds"
    if is_table(config) then
      dict.merge(specs, { config })
    end
  end

  return Autocmd.fromdict(specs)
end

function Autocmd.main()
  return Autocmd.require()
end
