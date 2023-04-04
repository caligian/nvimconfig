require "utils.Set"
require "utils.Array"
require "utils.Dict"

valid_types = {
  number = "number",
  n = "number",

  string = "string",
  s = "string",

  ["function"] = "callable",
  f = "callable",

  table = "table",
  t = "table",

  class = "class",
  c = "class",

  userdata = "userdata",
  u = "userdata",

  boolean = "boolean",
  b = "boolean",

  thread = "thread",
  th = "thread",

  struct = 'struct',
  st = 'struct',

  pure_table = 'pure_table',
  pt = 'pure_table',
}

function is_number(x)
  return type(x) == "number"
end
function is_string(x)
  return type(x) == "string"
end
function is_userdata(x)
  return type(x) == "userdata"
end
function is_table(x)
  return type(x) == "table"
end
function is_thread(x)
  return type(x) == "thread"
end
function is_boolean(x)
  return type(x) == "boolean"
end
function is_function(x)
  return type(x) == "function"
end
function is_nil(x)
  return x == nil
end

function is_class(obj)
  if not is_table(obj) then
    return false
  end
  local mt = getmetatable(obj)
  if mt then
    return mt.type == "class"
  end
end

function is_callable(x)
  if is_function(x) then
    return true
  end
  if not is_table(x) then
    return false
  end
  local mt = getmetatable(x) or {}
  return is_function(mt.__call)
end

function is_struct(x)
  local mt = getmetatable(x) or {}
  if not mt then
    return false
  end
  return mt.type == "struct"
end

function is_pure_table(x)
  if type(x) == "table" and not is_class(x) then
    return true
  end
  return false
end

function mtget(t, k)
  if not is_table(t) then
    return
  end

  local mt = getmetatable(t)

  if not mt then
    return
  elseif k then
    return mt[k]
  else
    return mt
  end
end

function mtset(t, k, v)
  local mt = mtget(t)
  if not mt then
    return
  end
  mt[k] = v

  return mt
end

function typeof(obj)
  if is_class(obj) then
    return "class"
  elseif is_callable(obj) then
    return "callable"
  elseif is_table(obj) then
    return "table"
  else
    return type(obj)
  end
end

local function _is_a(x, y)
  if x == nil or y == nil then
    return false
  elseif x == y then
    return true
  elseif is_function(y) then
    local ok, msg = y(x)
    if not ok then
      return false, msg or 'callabled failed ' .. tostring(x)
    end
    return true
  elseif is_string(y) then
    local ok, msg
    y = valid_types[y] or y
    if y == 'pure_table' then
      ok = is_pure_table(x)
      if not ok then
        if is_class(x) then
          x = x:get_name()
        else
          x = typeof(x)
        end
        return false, 'expected pure_table, got ' .. typeof(x)
      end
      return true
    elseif y == 'struct' then
      ok = is_struct(x)
      if not ok then
        if is_class(x) then
          x = x:get_name()
        else
          x = typeof(x)
        end
        return false, 'expected struct, got ' .. x
      end
      return true
    else
      if is_class(x) then
        local tp = x:get_name()
        if tp ~= y then
          return false, 'expected ' .. y  .. ', got ' .. tp
        end
        return true
      end

      local tp = typeof(x)
      if tp ~= y then
        return false, 'expected ' .. y  .. ', got ' .. tp
      end
      return true
    end
  elseif is_class(x) then
    local ok = x:is_a(y)
    if not ok then
      return false, 'expected ' .. y .. ', got ' .. x:get_name()
    end
    return true
  elseif is_class(y) then
    if is_class(x) then
      local ok, msg
      local y_name = y:get_name()
      local x_name = x:get_name()
      ok = x_name == y_name
      if not ok then
        return false, 'expected ' .. y_name .. ', got ' .. x_name
      end
    else
      local y_name = y:get_name()
      local x_name = typeof(x)
      local ok, msg
      ok = y_name == x_name
      if not ok then
        return false, 'expected ' .. y_name .. ', got ' .. x_name
      else
        return true
      end
    end
  else
    local ok = typeof(x) == typeof(y)
    if not ok then
      return false, 'expected ' .. y .. ', got ' .. x
    end
    return true
  end
end

is_a = setmetatable({}, {
  __index = function(self, spec)
    return function(obj)
      return _is_a(obj, valid_types[spec] or spec)
    end
  end,
  __call = function(_, obj, spec)
    return _is_a(obj, spec)
  end,
})

local function get_name(x)
  if not is_table(x) then
    return typeof(x)
  end

  local tp = mtget(x, "type")
  local name = mtget(x, "name")
  if tp and name then
    return sprintf("[%s] %s", tp, name)
  elseif tp then
    return tp
  elseif is_callable(x) then
    return "callable"
  else
    return "table"
  end
end

function is(type_spec)
  if not is_pure_table(type_spec) then
    type_spec = { type_spec }
  end

  local display_spec = Array.map(type_spec, function(x)
    if valid_types[x] then
      return valid_types[x]
    end
    return get_name(x)
  end)

  return function(e)
    local invalid = {}
    local i = 1

    Array.each(type_spec, function(spec)
      if not is_a(e, spec) then
        invalid[i] = display_spec[i]
        i = i + 1
      end
    end)

    if #invalid == #type_spec then
      return false, string.format("expected %s, got %s", table.concat(invalid, "|"), get_name(e))
    end

    return true
  end
end

local function _throw_error(display, fmt, ...)
  error(display .. ": " .. sprintf(fmt, ...))
end

local function _validate2(a, b)
  opts = opts or {}

  local function _compare(a, b)
    if not is_table(b) then
      error(
        sprintf(
          "%s: table expected, got %s",
          a.__table or tostring(a),
          typeof(b)
        )
      )
    end

    local nonexistent = a.__nonexistent == nil and true or a.__nonexistent
    local level_name = a.__table or tostring(a)
    a.__nonexistent = nil
    a.__table = nil
    local optional = {}
    local ks_a = table.keys(a)
    local ks_b = table.keys(b)

    Array.ieach(ks_a, function(idx, k)
      k = tostring(k)
      local opt = k:match "^%?"
      local _k = k:gsub("^%?", "")
      if opt then
        optional[_k] = true
      end
      if _k:match "^[0-9]+$" then
        _k = tonumber(_k)
      end
      ks_a[idx] = _k
    end)

    ks_a = Set.new(ks_a)
    ks_b = Set.new(ks_b)
    local common = ks_a ^ ks_b
    local missing = ks_a - ks_b
    local foreign = ks_b - ks_a

    missing:each(function(k)
      if optional[k] then
        return
      else
        error(string.format("%s: missing key: %s", level_name, dump(missing:items())))
      end
    end)

    if not nonexistent then
      assert(
        foreign:len() == 0,
        string.format("%s: unrequired table.keys: %s", level_name, dump(foreign:items()))
      )
    end

    common:each(function(key)
      display = key:gsub("^%?", "")
      local tp, param

      if optional[display] then
        tp = a["?" .. display]
      else
        tp = a[display]
      end

      param = b[display]

      if optional[display] and param == nil then
        return
      end

      local ok, msg = is_a(param, tp)
      if is_pure_table(tp) and ok then
        _validate2(tp, param)
      else
        assert(ok, msg)
      end
    end)

    return b
  end

  return _compare(a, b)
end

local function _validate(type_spec)
  Dict.each(type_spec, function(display, spec)
    local tp, param = unpack(spec)
    if display:match "^%?" and param == nil then return end
    display = display:gsub("^%?", "")

    if is_pure_table(tp) then 
      tp.__table = display 
      _validate2(tp, param)
    else
      local ok, msg = is_a(param, tp)
      if not ok then
      end
    end
  end)
end

validate = setmetatable({}, {
  __index = function(_, display)
    return function(spec, obj)
      _validate { [display] = { spec, obj } }
    end
  end,
  __call = function(_, ...)
    _validate(...)
  end,
})

isa = function(spec, param)
  if not param then
    return function(param)
      validate.param(spec, param)
      return param
    end
  end

  validate.param(spec, param)

  return param
end

struct = function(spec)
  validate.spec("table", spec)
  spec.__nonexistent = false
  return setmetatable({}, {
    type = 'struct',
    __call = function (self, t)
      validate.param('pure_table', t)
    end
  })
end

t_string = isa "string"
t_number = isa "number"
t_table = isa "table"
t_class = isa "class"
t_boolean = isa "boolean"
t_userdata = isa "userdata"
t_boolean = isa "boolean"
t_thread = isa "thread"
t_fun = isa "function"
t_callable = isa "callable"
t_Array = isa(Array)
t_Dict = isa(Dict)
