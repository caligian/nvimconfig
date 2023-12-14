require "core.utils.au"

if not kbd then
  kbd = class "kbd"
  kbd.kbds = {}
end

local enable = vim.keymap.set
local delete = vim.keymap.del
local del = delete

function kbd.opts(self)
  return dict.filter(self, function(key, _)
    return strmatch(
      key,
      "buffer",
      "nowait",
      "silent",
      "script",
      "expr",
      "unique",
      "noremap",
      "desc",
      "callback",
      "replace_keycodes"
    )
  end)
end

function kbd.init(self, mode, ks, callback, rest)
  rest = rest or {}
  mode = mode or "n"

  local _rest = rest
  rest = isstring(_rest) and { desc = _rest } or _rest

  mode = isstring(mode) and split(mode, "") or mode
  local command = isstring(callback) and callback
  callback = iscallable(callback) and callback
  local prefix = rest.prefix
  local noremap = rest.noremap
  local event = rest.event
  local pattern = rest.pattern
  local once = rest.once
  local buffer = rest.buffer
  local cond = rest.cond
  local localleader = rest.localleader
  local leader = rest.leader
  local name = rest.name
  local group = rest.group or "Keybinding"
  local desc = rest.desc

  if prefix and (localleader or leader) then
    if localleader then
      ks = "<localleader>" .. prefix .. ks
    else
      ks = "<leader>" .. prefix .. ks
    end
  elseif localleader then
    ks = "<localleader>" .. ks
  elseif leader then
    ks = "<leader>" .. ks
  end

  if name then
    if group then
      name = group .. "." .. name
    end
  end

  self.mode = mode
  self.keys = ks
  self.command = command
  self.prefix = prefix
  self.noremap = noremap
  self.event = event
  self.pattern = pattern
  self.once = once
  self.buffer = buffer
  self.cond = cond
  self.localleader = localleader
  self.leader = leader
  self.name = name
  self.desc = desc
  self.enabled = false
  self.au = false
  self.callback = callback

  if name then
    kbd.kbds[name] = self
  end

  return self
end

function kbd.enable(self)
  if self.au and au.exists(self.au) then
    return self
  end

  local opts = copy(kbd.opts(self))
  local cond = self.cond
  local callback

  if self.command then
    callback = self.command
  else
    callback = ""
    opts.callback = self.callback
  end

  if self.event and self.pattern then
    self.au = au(self.event, {
      pattern = self.pattern,
      group = self.group,
      once = self.once,
      callback = function(au_opts)
        if cond and not cond() then
          return
        end
        opts = copy(opts)
        opts.buffer = buffer.bufnr()

        enable(self.mode, self.keys, callback, opts)
        self.enabled = true
      end,
    })
  else
    enable(self.mode, self.keys, callback, opts)
    self.enabled = true
  end

  return self
end

function kbd.disable(self)
  if self.buffer then
    if self.buffer then
      del(self.mode, self.keys, { buffer = self.buffer })
    end
  elseif self.events and self.pattern then
    del(self.mode, self.keys, { buffer = buffer.bufnr() })
  else
    del(self.mode, self.keys)
  end

  if self.au then
    au.disable(self.au)
  end

  return self
end

function kbd.map(mode, ks, callback, opts)
  return kbd.enable(kbd(mode, ks, callback, opts))
end

function kbd.noremap(mode, ks, callback, opts)
  opts = isstring(opts) and { desc = opts } or opts
  opts = opts or {}
  opts.noremap = true

  return kbd.map(mode, ks, callback, opts)
end

function kbd.map_group(group_name, specs, compile)
  local mapped = {}
  local opts = specs.opts
  local apply = specs.apply

  dict.each(specs, function(name, spec)
    if name == "opts" or name == "apply" then
      return
    end

    if isa.kbd(spec) then
      kbd.enable(spec)
      return
    end

    name = group_name .. "." .. name
    local mode, ks, callback, rest

    if opts then
      ks, callback, rest = unpack(spec)
      rest = isstring(rest) and { desc = rest } or rest
      rest = dict.merge(copy(rest or {}), opts or {})
      mode = rest.mode or "n"
    else
      mode, ks, callback, rest = unpack(spec)
      rest = isstring(rest) and { desc = rest } or rest
      rest = copy(rest or {})
      rest.name = name
    end

    if apply then
      mode, ks, callback, rest =
        apply(mode, ks, callback, rest)
    end

    if compile then
      mapped[name] = kbd(mode, ks, callback, rest)
    else
      mapped[name] = kbd.map(mode, ks, callback, rest)
    end
  end)

  return mapped
end

function kbd.map_groups(specs, compile)
  local all_mapped = {}
  local opts = specs.opts
  specs = deepcopy(specs)
  specs.opts = nil

  dict.each(specs, function(group, spec)
    if dict.isa(spec, "kbd") then
      dict.merge(all_mapped, kbd.map_group(group, spec))
    elseif group == "inherit" then
      return
    elseif spec.opts and opts then
      dict.merge(spec.opts, opts)
    elseif spec.inherit then
      spec.opts = opts
    end

    spec.inherit = nil
    specs[group] = spec
  end)

  dict.each(specs, function(group, spec)
    dict.merge(
      all_mapped,
      kbd.map_group(group, spec, compile)
    )
  end)

  return all_mapped
end

function kbd.fromdict(specs)
  local out = {}
  for key, value in pairs(specs) do
    value[4] = isstring(value[4]) and { desc = value[4] } or value[4]
    value[4].name = key
    out[key] = kbd.map(unpack(value))
  end

  return out
end

function kbd.loadfile()
  local src = req2path "core.defaults.kbd"
  local usersrc = req2path "user.kbd"
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

  return kbd.fromdict(specs)
end

function kbd.require()
  local src = req2path "core.defaults.kbd"
  local usersrc = req2path "user.kbd"
  local specs = {}

  if usersrc then
    local config = requirex "core.defaults.kbd"
    if istable(config) then
      dict.merge(specs, config)
    end
  end

  if src then
    local config = requirex "core.defaults.kbd"
    if istable(config) then
      dict.merge(specs, config)
    end
  end

  return kbd.fromdict(specs)
end

function kbd.main()
  return kbd.require()
end
