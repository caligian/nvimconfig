Module = Module or {}
setmetatable(
  Module,
  { type = "Module", is_a = { [Module] = true, Module = true, table = true } }
)

function Module.is_module(x)
  if type(x) ~= "table" then return false end
  local mt = getmetatable(x)
  if not mt then return false end
  return mt.is_a.Module
end

function Module.inherit(mod1, mod2)
  assert(Module.is_module(mod1), "Module expected, got " .. tostring(mod1))
  assert(Module.is_module(mod2), "Module expected, got " .. tostring(mod2))

  for name, val in pairs(mod2) do
    mod1[name] = val
  end

  return mod1
end

function Module.inherit_table(mod1, mod2)
  assert(Module.is_module(mod1), "Module expected, got " .. tostring(mod1))
  assert(type(mod2) == "table", "table expected, got " .. tostring(mod1))

  for name, val in pairs(mod2) do
    mod1[name] = val
  end

  return mod1
end

function Module.get_mt(m) return getmetatable(m) end

function Module.get_methods(m)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))
  return m:_get_mt().methods
end

function Module.get_vars(m)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))
  return m:_get_mt().vars
end

function Module.freeze(m)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))

  local mt = m:get_mt()
  if mt.frozen then return m end
  mt.frozen = true
  mt.temp = mt.temp or {}
  mt.temp.__newindex = mt.__newindex
  mt.__newindex = function(self, k, v)
    error(
      sprintf(
        "%s: Attempting to edit a readonly Module with %s and %s",
        tostring(self),
        tostring(k),
        tostring(v)
      )
    )
  end

  return m
end

function Module.repr(m)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))
  return dump(m)
end

function Module.get_name(m)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))
  local mt = m:get_mt()
  return mt.name
end

function Module.get_type(m)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))
  local mt = m:get_mt()
  return mt.type
end

function Module.is_a(m, spec)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))
  local mt = m:get_mt()
  return mt.is_a[spec]
end

function Module.unfreeze(m)
  assert(Module.is_module(m), "Module expected, got " .. tostring(m))
  local mt = m:get_mt()
  if not mt.frozen then return m end
  mt.frozen = false
  mt.__newindex = mt.temp.__newindex
  mt.temp = nil

  return m
end

local function is_callable(x)
  if type(x) == "function" then return true end
  if type(x) ~= "table" then return false end
  local mt = getmetatable(x) or {}

  return mt.__call == nil and false or true
end

function Module.new(name, base)
  assert(type(name) == "string", "name: string expected, got " .. type(name))
  assert(
    name:match "^[A-Za-z0-9_]+$",
    "name: Should only contain alphanumeric characters"
  )
  assert(
    string.sub(name, 1, 1):match "[A-Z]",
    "name: Should start with a capital letter"
  )

  if base then
    assert(Module.is_module(base), "module expected, got " .. tostring(base))
  end

  local self = {}
  local id = vim.split(tostring(self), ":")[2]
  local mt = {
    instance = true,
    type = "Module",
    name = name,
    methods = {},
    vars = {},
    is_a = {
      [Module] = true,
      [self] = true,
      [name] = true,
      Module = true,
      table = true,
    },
  }

  mt.__index = function(self, k)
    if mt.methods[k] then return self.methods[k] end
    if mt.vars[k] then return self.vars[k] end

    return rawget(self, k)
  end

  mt.__newindex = function(self, k, v)
    rawset(self, k, v)

    if is_callable(v) then
      mt.methods[k] = v
    else
      mt.vars[k] = v
    end
  end

  mt.__tostring = function(self) return mt.name .. ":" .. id end

  mt.__call = function (self, ...)
    if self.constructor then
      self.constructor(self, ...)
      return self
    end
    return self, ...
  end

  setmetatable(self, mt)

  for name, val in pairs(Module) do
    if name ~= "module" and name ~= "new" then self[name] = val end
  end

  return self
end

function module(name, base, force)
  if _G[name] and not force then return _G[name] end
  local m = Module.new(name, base)
  _G[name] = m

  return m
end
