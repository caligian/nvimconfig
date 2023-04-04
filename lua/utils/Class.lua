local Class = {}

local valid_mt_ks = {
  __ge = true,
  __gt = true,
  __le = true,
  __lt = true,
  __add = true,
  __sub = true,
  __mul = true,
  __div = true,
  __mod = true,
  __pow = true,
  __tostring = true,
  __tonumber = true,
  __index = true,
  __newindex = true,
  __call = true,
  __metatable = true,
  __mode = true,
}

local function get_mt(obj, k)
  if type(obj) ~= "table" then
    return false
  end
  local mt = getmetatable(obj)
  if not mt then
    return
  end
  if k then
    return mt[k]
  end

  return mt
end

local function is_ancestor_of(parent, child)
  local mt_c = get_mt(child)
  local mt_p = get_mt(parent)

  if mt_c == parent then
    return true
  elseif not mt_p and not mt_c then
    return false
  elseif parent == child then
    return false
  end

  parent = mt_p.class
  local child_parent = mt_c.parent
  while child_parent do
    if parent == child_parent then
      return true
    end
    child_parent = get_mt(child_parent, "parent")
  end

  return false
end

local function is_instance_of(inst, cls)
  local inst_mt = get_mt(inst)
  if not inst_mt then
    return false
  end
  return inst.class == cls
end

local function is_class(obj)
  return get_mt(obj, "type") == "class"
end

local function is_instance(inst)
  if not is_class(inst) then
    return false
  end

  return inst.class ~= nil
end

local function is_callable(f)
  return get_mt(f, "__call") or type(f) == "function"
end

local function get_method(obj, k)
  local m = obj[k]
  if not m then
    return
  end
  if is_instance(obj) then
    return function(...)
      return obj[k](obj, ...)
    end
  end
  return obj[k]
end

local function include(obj, t, use_attrib)
  for key, value in pairs(t) do
    if is_callable(value) then
      obj[key] = function(inst, ...)
        return value(inst[use_attrib] or inst, ...)
      end
    else
      obj[key] = value
    end
  end
end

local function is_a(x, y)
  if x == y then
    return true
  elseif type(y) ~= "table" then
    return false
  end

  local mt_x = get_mt(x)
  local mt_y = get_mt(y)

  if not mt_y then
    return false
  elseif mt_x.class == mt_y.class then
    return true
  elseif mt_x == y then
    return true
  end

  return is_ancestor_of(y, x)
end

local function is_parent_of(parent, child)
  return is_a(child, parent)
end

local function is_child_of(child, parent)
  return is_a(child, parent)
end

local function get_name(obj)
  return get_mt(obj, "name")
end

local function get_parent(obj)
  return get_mt(obj, "parent")
end

local function get_class(obj)
  return get_mt(obj)
end

local function super(obj)
  local parent = obj:get_parent()
  if parent and parent.init then
    return parent.init
  end
  return function(...)
    return ...
  end
end

function Class.new(name, opts)
  opts = opts or {}
  local parent = opts.parent
  local is_global = opts.global
  local cls = {
    is_instance_of = is_instance_of,
    is_ancestor_of = is_ancestor_of,
    is_parent_of = is_parent_of,
    is_child_of = is_child_of,
    get_parent = get_parent,
    get_method = get_method,
    get_name = get_name,
    get_class = get_class,
    include = include,
    is_a = is_a,
    super = super,
  }

  local mt = {}
  mt.type = "class"
  mt.name = name
  mt.class = cls

  mt.__newindex = function(self, k, v)
    if valid_mt_ks[k] then
      mt[k] = v
    else
      rawset(self, k, v)
    end
  end

  mt.__index = function(_, k)
    if valid_mt_ks[k] then
      return mt[k]
    elseif parent then
      return parent[k]
    end
  end

  if is_class(parent) then
    mt.parent = parent
  end

  cls.new = function(...)
    local obj = setmetatable({ class = cls }, mt)

    for key, value in pairs(cls) do
      obj[key] = value
    end

    if not cls.init then
      cls.init = function(_)
        return _
      end
    end

    cls.init(obj, ...)
    return obj
  end

  if is_global then
    _G[name] = cls
  end

  mt.__call = function(_, ...)
    return cls.new(...)
  end

  return setmetatable(cls, mt)
end

function class(name, base)
  return Class.new(name, { parent = base, global = true })
end
