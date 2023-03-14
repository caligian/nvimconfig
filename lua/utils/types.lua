TYPES = {
  s = "string",
  t = "table",
  u = "userdata",
  n = "number",
  f = "callable",
  b = "boolean",
  c = "class",
  string = "string",
  table = "table",
  userdata = "userdata",
  number = "number",
  boolean = "boolean",
  ["function"] = "callable",
  callable = "callable",
  Set = "Set",
  Map = "Map",
  OrderedMap = "OrderedMap",
  MultiMap = "MultiMap",
  Date = "Date",
  Lang = "Lang",
  Colorscheme = "Colorscheme",
  REPL = "REPL",
  Buffer = "Buffer",
  Autocmd = "Autocmd",
  Keybinding = "Keybinding",
  A = "Autocmd",
  K = "Keybinding",
  B = "Buffer",
  Process = "Process",
}

function class_of(e)
  if type(e) ~= "table" then
    return false
  end
  if e._class then
    return e._class
  end
  local mt = getmetatable(e) or {}
  if mt._class then
    return mt._class
  end
end

function is_instance(e, cls)
  if type(e) ~= "table" then
    return false
  end
  if type(cls) ~= "table" then
    return false
  end

  return class_of(e) == class_of(cls)
end

function is_callable(t)
  local k = type(t)
  if k ~= "table" and k ~= "function" then
    return false
  elseif k == "function" then
    return true
  end

  local mt = getmetatable(t)
  if mt then
    if mt.__call then
      return true
    end
  end
  return false
end

function get_class(e)
  if type(e) == "string" then
    local g = _G[e]
    if type(g) == "table" then
      return (class_of(g) or false)
    end
  end

  if type(e) ~= "table" then
    return false
  end
  return (class_of(e) or false)
end

function is_class(e)
  if type(e) ~= "table" then
    return false
  end

  return get_class(e) or false
end

function is_table(obj)
  return type(obj) == "table"
end

function class_name(obj)
  cls = get_class(obj)
  if cls then
    return cls._name
  end
  return false
end

function is_pure_table(t)
  return is_table(t) and not getmetatable(t)
end

function typeof(x)
  if type(x) == "table" then
    local cls = get_class(x)
    if cls then
      return cls
    else
      local mt = getmetatable(x) or {}
      if mt.__call then
        return "callable"
      end
      return "table"
    end
  elseif type(x) == "function" then
    return "callable"
  end

  return type(x)
end

local _is_a = function(e, k)
  if TYPES[k] then
    k = TYPES[k]
  end

  local e_cls, k_cls
  if k == "table" or k == table or k == "string" or k == string then
    if k == table then
      k = "table"
    elseif k == string then
      k = "string"
    end
    return type(e) == k
  elseif _G[k] then
    local g = _G[k]
    e_cls = get_class(e)
    k_cls = get_class(g)
  else
    e_cls = get_class(e)
    k_cls = get_class(k)
  end

  if e_cls and k_cls then
    local e_name, k_name = class_name(e_cls), class_name(k_cls)
    if e_name and k_name then
      return e_name == k_name
    end
    return e_cls == k_cls
  elseif e_cls and k == "table" then
    return true
  elseif k_cls then
    return false
  elseif k == "callable" then
    return is_callable(e)
  elseif k == "class" then
    return is_class(e)
  end

  return type(e) == k
end

is_a = setmetatable({}, {
  __call = function(self, e, ...)
    local args = { ... }
    local out = false
    for _, tp in ipairs(args) do
      out = out or self[tp](e)
    end
    return out
  end,

  -- Only works for native datatypes + callables
  __index = function(_, k)
    return function(e)
      return _is_a(e, k)
    end
  end,
})
