require "utils.table"

Class = {}
local Mt = {}
setmetatable(Class, Mt)

local valid_mt_ks = {
  __unm = true,
  __eq = true,
  __ne = true,
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

local function assert_is_class(cls)
  assert(is_class(cls), "expected class, got " .. tostring(cls))
end

comparators = {
  eq = function(self, other)
    assert_is_class(other)

    local vars = get_vars(other)
    local self_vars = get_vars(self)

    for key, value in pairs(self_vars) do
      local self_value = self[key]
      local ok
      if not self_value then
        ok = false
      elseif not is_class(value) and is_table(value) then
        if is_class(self_value) or not is_table(self_value) then
          ok = false
        else
          ok = select(2, table.compare(self_value, value))
        end
      else
        ok = self[key] == value
      end

      if not ok then return false end
    end

    return true
  end,

  equal = function(self, other)
    assert_is_class(other)

    local vars = get_vars(other)
    local self_vars = get_vars(self)
    local ok

    for key, value in pairs(self_vars) do
      if not self[key] then
        ok = false
      else
        ok = self[key] == value
      end

      if not ok then return false end
    end

    return true
  end,

  name = function(self, other) return get_name(self) == get_name(other) end,
}

comparators.not_equal = function(self, other)
  return comparators.equal(self, other)
end

comparators.not_eq = function(self, other) return comparators.eq(self, other) end

comparators.not_name = function(self, other)
  return comparators.name(self, other)
end

function is_instance_of(inst, cls)
  return is_instance(inst) and get_class(inst) == get_class(cls) or false
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

function get_methods(obj)
  return dict.grep(obj, function(_, value) return is_callable(value) end)
end

function get_vars(obj)
  return dict.grep(
    obj,
    function(_, value) return is_callable(value) ~= true end
  )
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

function get_attrib(obj, k) return obj[k] end

function get_attribs(obj)
  local out = {}
  for key, value in pairs(obj) do
    out[key] = value
  end
  return out
end

function include(obj, t, opts)
  assert(is_table(t), "table expected, got " .. tostring(t))

  opts = opts or {}

  dict.each(t, function(key, value)
    if not is_callable(value) then
      obj[key] = value
    elseif opts.attrib then
      obj[key] = function(self, ...)
        if is_instance(self) then
          return value(self[opts.attrib], ...)
        else
          return value(self, ...)
        end
      end
    elseif not opts.ignore_methods then
      obj[key] = value
    end
  end)

  return obj
end

function is_child_of(child, parent)
  return get_parent(child) == get_class(parent)
end

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

function create_class(name, parent, opts)
  if parent then
    assert(
      is_class(parent) and not is_instance(parent),
      "non-instantiated class expected, got " .. type(parent)
    )
  end

  opts = opts or {}
  local mt = { name = name, parent = parent, type = "class" }
  local cls = setmetatable(copy(Class), mt)

  local __eq = opts.__eq
  if __eq then
    if __eq.equal then
      cls.__eq = comparators.equal
      cls.__ne = comparators.not_equal
    elseif __eq.eq then
      cls.__eq = comparators.eq
      cls.__ne = comparators.not_equal
    elseif __eq.name then
      cls.__eq = comparators.name
      cls.__ne = comparators.not_name
    end
  end

  local include = opts.include
  local attrib = opts.attrib

  if include and attrib then
    include(cls, include, { attrib = attrib })
  elseif include then
    include(cls, include)
  end

  function cls.__newindex(self, k, v)
    if valid_mt_ks[k] then
      if is_instance(self) then
        error "cannot set metamethod on an instance"
      else
        mt[k] = v
      end
    else
      rawset(self, k, v)
    end
  end

  function cls.__index(self, k)
    if Class[k] then
      return Class[k]
    else
      local _cls = get_class(self)
      local _mt = mtget(cls)
      local _parent = get_parent(cls)
      if cls ~= _cls then
        return _cls[k]
      elseif valid_mt_ks[k] and _mt[k] then
        return _mt[k]
      elseif _parent then
        return _parent[k]
      end
    end
  end

  cls.new = function(...)
    local obj = setmetatable(copy(cls), cls)
    obj.__newindex = nil
    obj.__index = nil
    if obj.init then
      obj:init(...)
    elseif parent and parent.init then
      parent.init(obj, ...)
    end

    return obj
  end

  mt.__newindex = cls.__newindex
  mt.__index = cls.__index
  function mt:__call(...) return cls.new(...) end

  return cls
end

function Class.new(name, parent, opts) return create_class(name, parent, opts) end

function Mt.__call(_, name, parent, opts) return Class.new(name, parent, opts) end

function class(name, parent, opts)
  local cls = Class(name, parent)
  _G[name] = cls

  return cls
end

function datashape(name, parent, opts)
  opts = opts or {}

  if not opts.__eq then
    opts.__eq = { eq = true }
  elseif not opts.__eq.eq and not opts.__eq.equal then
    opts.__eq.eq = true
  end

  return Class.new(name, parent, opts)
end
