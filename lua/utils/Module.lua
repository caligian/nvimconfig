Module = Module or {}

local function getmt(obj)
  if not type(obj) == "table" then return end
  return getmetatable(obj)
end

function Module.get_name(obj)
  local mt = getmt(obj)
  if mt then return mt.name end
end

local function is_callable(x)
  if type(x) == "table" then
    local mt = getmetatable(x)
    if mt.__call then return true end
  elseif type(x) == "function" then
    return true
  end
  return false
end

function Module.get_methods(obj)
  local f = {}
  for key, value in pairs(obj) do
    if is_callable(value) then
      f[key] = value
    end
  end

  return f
end

function Module.get_method(obj, m)
  local f = Module.get_methods(obj)
  if not f then return end

  return f[m]
end

function Module.include(obj, t)
  for key, value in pairs(t) do
    obj[key] = value
  end

  return obj
end

function Module.is_module(obj)
  if type(obj) ~= 'table' then return false end
  local mt = getmetatable(obj)
  if not mt then return false end

  return mt.type == 'module'
end

function Module.new(name, include)
  local cls = {}
  local mt = {}
  mt.type = "module"
  mt.name = name
  mt.__index = cls
  mt.__name = name

  for key, value in pairs(Module) do
    if key ~= "new" then cls[key] = value end
  end

  if include then
    Module.inherit(cls, include)
  end

  return setmetatable(cls, mt)
end

function module(name, include)
  local mod = Module.new(name, parent)
  _G[name] = mod

  return mod
end
