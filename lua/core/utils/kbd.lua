require "core.utils.au"

--- @class kbd

if not Kbd then
  Kbd = class "Kbd"
  user.kbds = {}
end

local enable = vim.keymap.set
local delete = vim.keymap.del
local del = delete

function Kbd.opts(self)
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

function Kbd.init(self, mode, ks, callback, rest)
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
  self.map = nil
  self.noremap = nil
  self.fromdict = nil
  self.require = nil
  self.loadfile = nil
  self.main = nil

  if name then
    user.kbds[name] = self
  end

  return self
end

function Kbd.enable(self)
  if self.au and au.exists(self.au) then
    return self
  end

  local opts = copy(Kbd.opts(self))
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
        opts.buffer = au_opts.buf

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

function Kbd.disable(self)
  if self.buffer then
    if self.buffer then
      del(self.mode, self.keys, { buffer = self.buffer })
    end
  elseif self.events and self.pattern then
    del(self.mode, self.keys, { buffer = buffer.bufnr() })
  else
    del(self.mode, self.keys, {})
  end

  if self.au then
    au.disable(self.au)
  end

  return self
end

function Kbd.map(mode, ks, callback, opts)
  return Kbd.enable(Kbd(mode, ks, callback, opts))
end

function Kbd.noremap(mode, ks, callback, opts)
  opts = isstring(opts) and { desc = opts } or opts
  opts = opts or {}
  opts.noremap = true

  return Kbd.map(mode, ks, callback, opts)
end

function Kbd.fromdict(specs)
  local out = {}
  for key, value in pairs(specs) do
    value[4] = not value[4] and { desc = key }
      or isstring(value[4]) and { desc = value[4] }
      or istable(value[4]) and value[4]
      or {desc = key}

    value[4] = copy(value[4])
    value[4].name = key
    value[4].desc = value[4].desc or key

    out[key] = Kbd.map(unpack(value))
  end

  return out
end

function Kbd.loadfile()
  local src = req2path "core.defaults.kbd"
  local usersrc = req2path "user.kbd"
  local specs = {}

  if src then
    local config = loadfile(src)
    if isfunction(config) then
      config = config--[[@as function]]()
      if istable(config) then
        dict.merge(specs, config)
      end
    end
  end

  if usersrc then
    local config = loadfile(usersrc)
    if isfunction(config) then
      config = config--[[@as function]]()
      if istable(config) then
        dict.merge(specs, config)
      end
    end
  end

  return Kbd.fromdict(specs)
end

function Kbd.require()
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

  return Kbd.fromdict(specs)
end

function Kbd.main()
  return Kbd.require()
end
