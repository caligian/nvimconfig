local _class = require "pl.class"

function class(name, base, force)
  assert(type(name) == "string", "name: string expected, got " .. type(name))
  assert(
    name:match "^[A-Za-z0-9_]+$",
    "name: Should only contain alphanumeric characters"
  )
  assert(
    string.sub(name, 1, 1):match "[A-Z]",
    "name: Should start with a capital letter"
  )

  if not _G[name] or force then return _class[name](base) end
end

Module = Module or {}

function Module.is_module(x)
  if type(x) == 'table' then return false end
  local mt = getmetatable(x)
  if not mt then return false end
  if not mt.properties then return false end

  return mt.properties.type == 'Module'
end

function Module.inherit(mod1, mod2)
  assert(Module.is_module(mod1), 'Module expected, got ' .. tostring(mod1))
  assert(Module.is_module(mod2), 'Module expected, got ' .. tostring(mod2))

  for name, val in pairs(mod2) do
    mod1[name] = val
  end

  return mod1
end

function Module.inherit_table(mod1, mod2)
  assert(Module.is_module(mod1), 'Module expected, got ' .. tostring(mod1))
  assert(type(mod2) == 'table', 'table expected, got ' .. tostring(mod1))

  for name, val in pairs(mod2) do
    mod1[name] = val
  end
  
  return mod1
end

local function is_callable(x)
  if type(x) == 'function' then return true end
  if type(x) ~= 'table' then return false end
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
    assert(Module.is_module(base), 'module expected, got ' .. tostring(base))
  end

  local self = {}
  local mt = {
    _properties = {type='Module', name=name},
    _methods = {},
    _vars = {},
  }

  mt.__index = function (self, k)
    if mt._methods[k] then
      return mt._methods[k]
    elseif mt._vars[k] then
      return mt._vars[k]
    elseif mt[k] then
      return mt[k]
    else
      return rawget(self, k)
    end
  end

  mt.__newindex = function (self, k, v)
    if k == '_properties'
      or k == '_methods'
      or k == '_vars' then
        error('Attempting to edit readonly property ' .. k)
    end

    if is_callable(v) then
      if k:match('^__') then
        mt[k] = v
      elseif not k:match('^_') then
        mt._methods[k] = v
      end
    else
      mt._vars[k] = v
    end
  end

  setmetatable(self, mt)

  for name, val in pairs(Module) do
    if name ~= 'module' and name ~= 'new' then
      self[name] = val
    end
  end

  return self
end
