Class = Class or {}

local function getmt(obj)
  if not type(obj) == "table" then return end
  return getmetatable(obj)
end

function Class.get_parent(obj)
  local mt = getmt(obj)
  if mt then return mt.parent end
end

function Class.get_name(obj)
  local mt = getmt(obj)
  if mt then return mt.name end
end

function Class.get_class(obj) return getmetatable(obj) end

local function is_callable(x)
  if type(x) == "table" then
    local mt = getmetatable(x)
    if mt.__call then return true end
  elseif type(x) == "function" then
    return true
  end
  return false
end

function Class.get_methods(obj)
  local f = {}
  for key, value in pairs(obj) do
    if is_callable(value) then
      f[key] = value
    end
  end

  return f
end

function Class.get_method(obj, m)
  local f = Class.get_methods(obj)
  if not f then return end

  return f[m]
end

function Class.get_vars(obj)
  local vars = {}
  for key, value in pairs(obj) do
    if not is_callable(value) then vars[key] = value end
  end

  return vars
end

function Class.get_var(obj, v)
  local vars = Class.get_vars(obj)
  if not vars then return end
  return vars[v]
end

function Class.is_class(obj)
  local mt = getmt(obj)
  if not mt then return end
  return mt.type == "class"
end

local function assert_cls(obj)
  assert(Class.is_class(obj), "class expected, got " .. tostring(obj))
end

function Class.is_a(obj, cls)
  assert_cls(obj)

  local mt = getmt(obj)
  while mt do
    if mt == cls then return true end
    mt = mt.parent
  end

  return false
end

function Class.inherit(obj, parent)
  assert_cls(parent)

  local mt = getmt(obj)
  mt.parent = parent
  for name, val in pairs(parent) do
    obj[name] = val
  end

  return obj
end

function Class.include(obj, t, dispatch_key)
  assert_cls(obj)

  if dispatch_key then
    assert(obj[dispatch_key], 'expected valid dispatch key, got ' .. tostring(dispatch_key))
  end

  for key, value in pairs(t) do
    if dispatch_key then
      obj[key] = function (_, ...)
        return value(obj[dispatch_key], ...)
      end
    else
      obj[key] = value
    end
  end

  return obj
end

function Class.new(name, parent)
  if parent then assert_cls(parent) end

  local mt = {}

  for key, value in pairs(Class) do
    if key ~= "new" then cls[key] = value end
  end

  mt.parent = parent
  mt.type = "class"
  mt.name = name
  mt.__name = name

  mt.__index = function (self, k)
    if parent then
      return parent[k]
    end
  end

  mt.__newindex = function (self, k, v)
    if k:match('^__') then
      mt[k] = v
    else
      rawset(self, k, v)
    end
  end

  mt.__call = function(cls, ...)
    local instance = setmetatable({}, mt)
    for key, value in pairs(cls) do
      instance[key] = value
    end
    if cls.init then 
      cls.init(instance, ...) 
    elseif parent and parent.init then
      local parent_mt = getmt(parent)
      parent_mt.__call(instance, ...)
    end

    return instance
  end

  local cls = {}
  for key, value in pairs(Class) do
    if key ~= 'new' then
      cls[key] = value
    end
  end

  return setmetatable(cls, mt)
end

function class(name, parent)
  local cls = Class.new(name, parent)
  _G[name] = cls

  return cls
end
