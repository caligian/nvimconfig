dump = vim.inspect
trim = vim.trim
deepcopy = vim.deepcopy

function setro(t)
  assert(type(t) == "table", tostring(t) .. " is not a table")

  local function __newindex()
    error "Attempting to edit a readonly table"
  end

  local mt = getmetatable(t)
  if not mt then
    setmetatable(t, { __newindex = __newindex })
    mt = getmetatable(t)
  else
    mt.__newindex = __newindex
  end

  return t
end

function mtget(t, k)
  assert(type(t) == "table", tostring(t) .. " is not a table")
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t)
  if not mt then
    return nil
  end

  return mt[k]
end

function mtset(t, k, v)
  assert(type(t) == "table", tostring(t) .. " is not a table")
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t)
  if not mt then
    setmetatable(t, { [k] = v })
    mt = getmetatable(t)
  else
    mt[k] = v
  end

  return mt[k]
end

function isblank(s)
  assert(type(s) == "string" or type(s) == "table", "Need a string or a table")

  if type(s) == "string" then
    return #s == 0
  elseif type(s) == "table" then
    local i = 0
    for _, _ in pairs(s) do
      i = i + 1
    end
    return i == 0
  end
end

function split(s, delim)
  assert(type(s) == "string", "s is not a string")

  delim = delim or " "
  assert(type(delim) == "string", "delim is not a string")

  return vim.split(s, delim)
end

-- Type checking
local _tr = setmetatable({
  number = "number",
  table = "table",
  userdata = "userdata",
  ["function"] = "callable",
  callable = "callable",
  boolean = "boolean",
  string = "string",
  struct = "struct",
  module = "module",
  class = "class",
  c = "class",
  n = "number",
  t = "table",
  u = "userdata",
  f = "callable",
  b = "boolean",
  s = "string",
  r = "struct",
  m = "module",
}, {
  __index = function(self, k)
    if type(k) ~= "string" then
      k = type(k)
    end

    return rawget(self, k)
  end,
})

local function _is_class(t)
  local mt = getmetatable(t)
  if not mt then
    return false
  end

  if mt.__type == "class" then
    return true
  else
    return false
  end
end

local function _is_struct(t)
  local mt = getmetatable(t)
  if not mt then
    return false
  end

  if mt.__type == "struct" then
    return true
  else
    return false
  end
end

local function _is_module(t)
  local mt = getmetatable(t)
  if not mt then
    return false
  end

  if mt.__type == "module" then
    return true
  else
    return false
  end
end

local function _is_callable(f)
  if type(f) == "function" then
    return true
  elseif type(f) ~= "table" then
    return false
  end

  local mt = getmetatable(f) or {}
  if mt.__call then
    return true
  else
    return false
  end
end

local function _isa(e, c)
  if type(c) == "string" then
    if c == "c" or c == "class" then
      return _is_class(t)
    elseif c == "r" or c == "struct" then
      return _is_struct(e)
    elseif c == "m" or c == "module" then
      return _is_module(e)
    elseif c == "f" or c == "function" or c == "callable" then
      return _is_callable(e)
    else
      return type(e) == _tr[c]
    end
  elseif type(c) == "table" then
    if not type(e) == "table" then
      return false
    else
      local a = mtget(e, "__name")
      local b = mtget(c, "__name")
      if a == b then
        return true
      else
        return false
      end
    end
  else
    return type(e) == type(c)
  end
end

isa = setmetatable({}, {
  __call = function(_, e, c)
    if e == nil and c == nil then
      return true
    end

    return _isa(e, c)
  end,

  __index = function(_, k)
    assert(type(k) == "string" or type(k) == "table", "Spec is not a string or table")

    if type(k) == "string" and not _tr[k] then
      assert(_tr[k], "Invalid spec provided. Need any one of [ntufbsrm]")
    end

    return function(e)
      return _isa(e, k)
    end
  end,
})

--[[
Usage: 

validate {
  <display-var> = {
    <var>,
    <spec>,
  }
}

<var> string
Variable

<display-var> string
Varname to be used in assert

<spec> string|table
if <spec> == string then
  Either of [ntufbsrm]. 
  If prefixed with ?, it will be considered optional
elseif <spec> == 'table' then
  Will be recursively matched against var. isa will be used.
  If __allow_nonexistent (default: false) is passed, keys not present in <spec-table> will not raise an error.
end

--]]
local function _is_pure_table(t)
  return isa.t(t) and not isa.r(t) and not isa.m(t)
end

local function _error_s(name, t)
  name = name or "<nonexistent>"
  return string.format("%s is not of type %s", name, t)
end

local function _validate(name, var, test)
  assert(name, "name not provided")
  assert(var, "var not provided")
  assert(test, "test spec not provided")

  if isa.f(test) then
    assert(test(var), string.format("callable failed %s", name))
  elseif not isa.t(test) then
    assert(isa(var, test), _error_s(name, _tr[test]))
  else
    assert(isa.t(var), _error_s(name, "table"))

    if _is_pure_table(var) and _is_pure_table(test) then
      return "pure_table"
    else
      assert(isa(var, test), _error_s(name, test))
    end
  end
end

local function _validate_table(t, spec)
  local allowed = {}
  local allow_nonexistent = spec.__allow_nonexistent
  local id = spec.__name or tostring(t)
  spec.__name = nil
  spec.__allow_nonexistent = nil

  local not_supplied = {}
  for key, val in pairs(spec) do
    local name = key

    if name:match "^%?" then
      name = name:gsub("^%?", "")
      allowed[name] = "optional"
      spec[name] = val
      spec[key] = nil
    else
      allowed[name] = "required"
      if not t[name] then
        table.insert(not_supplied, name)
      end
    end
  end

  if #not_supplied > 0 then
    error(string.format("%s not supplied in %s", dump(not_supplied), id))
  end

  if not allow_nonexistent then
    for name, _ in pairs(t) do
      if not allowed[name] then
        error("unneeded key found: " .. name)
      end
    end
  end

  for name, var in pairs(t) do
    local required = spec[name]
    if required ~= nil then
      name = string.format("%s(%s)", id, name)
      if _validate(name, var, required) == "pure_table" then
        _validate_table(var, required)
      end
    end
  end
end

function validate(params)
  for name, param in pairs(params) do
    assert(isa.t(param) and #param == 2, name .. " should be {variable, spec}")

    local var, test = unpack(param)
    if _is_pure_table(var) and _is_pure_table(test) then
      _validate_table(var, test)
    else
      assert(isa(var, test), _error_s(name, test))
    end
  end
end
