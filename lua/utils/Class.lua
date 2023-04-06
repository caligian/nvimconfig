Class = {}
local Mt = {}
setmetatable(Class, Mt)

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

function mtget(obj, k)
  if type(obj) ~= "table" then return end
  local mt = getmetatable(obj)
  if not mt then return end
  if k then return mt[k], mt end
  return mt
end

function mtset(obj, k, v)
  if type(obj) ~= "table" then return end
  local mt = getmetatable(obj)
  if not mt then return end
  if k and v then
    mt[k] = v
    return v, mt
  end
end

function is_class(obj) return mtget(obj, "type") == "class" end

function is_instance(inst) return is_class(inst) and mtget(inst, "instance") end

function is_instance_of(inst, cls)
  return is_instance(inst) and get_class(inst) == get_class(cls) or false
end

function get_class(cls)
  if is_instance(cls) then
    return mtget(cls, "class")
  elseif is_class(cls) then
    return cls
  end
  return false
end

function get_parent(cls)
  if is_instance(cls) or is_class(cls) then return mtget(cls, "parent") end
  return false
end

function get_ancestors(cls)
  cls = get_class(cls)
  local ancestors = {}
  local ancestor = get_parent(cls)
  if not ancestor then return end
  ancestors[1] = ancestor
  local i = 2

  while ancestor do
    ancestor = get_parent(ancestor)
    if ancestor then
      ancestors[i] = ancestor
      i = i + 1
    end
  end

  return ancestors
end

function is_parent_of(cls, inst)
  return is_class(inst) and cls == get_parent(inst) or false
end

function is_ancestor_of(x, y)
  if not is_class(x) or not is_class(y) then return false end

  local parent = x
  local child_parent = get_parent(y)
  if parent == child_parent then return true end

  while parent do
    parent = get_parent(parent)
    if parent == child_parent then return true end
  end

  return false
end

function is_callable(f) return type(f) == "function" or mtget(f, "__call") end

local function copy_table(obj)
  local out = {}
  for key, value in pairs(obj) do
    out[key] = value
  end
  return out
end

function get_vars(obj)
  local out = {}
  for key, value in pairs(obj) do
    if not is_callable(value) then out[key] = value end
  end
  return out
end

function get_methods(obj)
  local out = {}
  for key, value in pairs(obj) do
    if is_callable(value) then out[key] = value end
  end
  return out
end

function get_method(obj, k)
  local methods = get_methods(obj)
  if not methods then return end
  return methods[k]
end

function get_var(obj, k)
  local vars = get_vars(obj)
  if not vars then return end
  return vars[k]
end

function get_attrib(obj, k) 
  return obj[k] 
end

function get_attribs(obj)
  local out = {}
  for key, value in pairs(obj) do
    out[key] = value
  end
  return out
end

function include(obj, t, use_attrib)
  for key, value in pairs(t) do
    if is_callable(value) then
      obj[key] = function(inst, ...) 
        if inst and is_class(inst) then
          return value(inst[use_attrib] or inst, ...)
        else
          return value(inst, ...)
        end
      end
		else
			obj[key] = value
    end
  end
  return obj
end

function is_child_of(child, parent)
  return get_parent(child) == get_class(parent)
end

function get_name(obj) return is_class(obj) and mtget(obj, "name") end

local function super(obj)
  local parent = get_parent(obj)
  if parent and parent.init then return parent.init end
  return function(...) return ... end
end

local function is_a(x, y)
  if x == y then return true end
  if not is_class(x) then return false end
  if not is_class(y) then return false end

  return get_class(x) == get_class(y) or is_ancestor_of(y, x) or false
end

Class.is_class = is_class
Class.is_instance_of = is_instance_of
Class.is_instance = is_instance
Class.get_class = get_class
Class.is_ancestor_of = is_ancestor_of
Class.get_parent = get_parent
Class.is_parent_of = is_parent_of
Class.get_vars = get_vars
Class.get_methods = get_methods
Class.get_method = get_method
Class.get_var = get_var
Class.get_attribs = get_attribs
Class.get_attrib = get_attrib
Class.include = include
Class.is_child_of = is_child_of
Class.get_name = get_name
Class.super = super
Class.is_a = is_a
Class.get_ancestors = get_ancestors

function create_instance(cls, ...)
  if cls then assert(is_class(cls), "class expected, got " .. type(cls)) end

  local obj = {class=cls}
  local mt = {}
  setmetatable(obj, mt)

  mt.type = "class"
  mt.class = cls
  mt.instance = true
  local parent = get_parent(cls)
  mt.parent = parent

  function mt.__newindex(self, k, v)
    if valid_mt_ks[k] then mt[k] = v end
    rawset(self, k, v)
  end

  function mt.__index(self, k)
    if valid_mt_ks[k] and mt[k] then
      return mt[k]
    elseif parent then
      return parent[k]
    end
  end

  include(obj, cls)

  if cls.init then
    cls.init(obj, ...)
  elseif parent and parent.init then
    parent.init(obj, ...)
  end

  return obj
end

function create_class(name, parent)
  if parent then
    assert(is_class(parent), "class expected, got " .. type(parent))
  end

  local cls = copy_table(Class)
  cls.new = nil
  local mt = {}
  setmetatable(cls, mt)

  mt.type = "class"
  mt.name = name
  mt.parent = parent

  if parent then include(cls, parent) end

  function mt.__newindex(self, k, v)
    if valid_mt_ks[k] then mt[k] = v end
    rawset(self, k, v)
  end

  function mt.__index(self, k)
    if valid_mt_ks[k] and mt[k] then
      return mt[k]
    elseif parent then
      return parent[k]
    end
  end

  mt.__call = create_instance
  cls.new = function(...)
    return create_instance(cls, ...)
  end

  return cls
end

function Class.new(name, parent)
  return create_class(name, parent)
end

function Mt.__call(_, name, parent)
  return Class.new(name, parent)
end

function class(name, parent)
  local cls = Class(name, parent)
  _G[name] = cls

  return cls
end
