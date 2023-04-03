require 'utils.Set'

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
}

function is_number(x) return type(x) == "number" end
function is_string(x) return type(x) == "string" end
function is_userdata(x) return type(x) == "userdata" end
function is_table(x) return type(x) == "table" end
function is_thread(x) return type(x) == "thread" end
function is_boolean(x) return type(x) == "boolean" end
function is_function(x) return type(x) == "function" end
function is_nil(x) return x == nil end

function is_class(obj)
  if not is_table(obj) then return false end
  return obj.type == "class"
end

function is_callable(x)
  if is_function(x) then return true end
  if not is_table(x) then return false end
  local mt = getmetatable(x) or {}
  return is_function(mt.__call)
end

function is_struct(x)
  local mt = getmetatable(x) or {}
  if not mt then
    return false
  end
  return mt.type == 'struct'
end

function is_pure_table(x)
  if type(x) ~= 'table' then
    return false
  elseif is_class(x) or is_callable(x) then
    return false
  end
  return true
end

function mtget(t, k)
  if not is_table(t) then return end

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
  if not mt then return end
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
  if x == nil then
    return y == nil
  elseif x == y then
    return true
  elseif is_string(y) then
    if valid_types[y] == 'pure_table' then
      return is_pure_table(x) == y
    else
      return typeof(x) == y
    end
  elseif is_table(x) then
    if x.is_a then
      return x:is_a(y)
    elseif is_table(y) then
      local name1, name2 = mtget(x, "name"), mtget(y, "name")
      if name1 and name2 then return name1 == name2 end
      local tp1, tp2 = mtget(x, "type"), mtget(y, "type")
      if tp1 and tp2 then return tp1 == tp2 end
    end
  else
    return typeof(x) == typeof(y)
  end

  return false
end

is_a = setmetatable({}, {
  __index = function(self, spec)
    return function(obj) return _is_a(obj, valid_types[spec] or spec) end
  end,
  __call = function(self, obj, ...)
    local specs = { ... }
    local i = 1
    local success = false
    while not success and i <= #specs do
      success = self[specs[i]](obj)
      i = i + 1
    end
    return success
  end,
})

local function get_name(x)
  if not is_table(x) then return typeof(x) end

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
  if not is_pure_table(type_spec) then type_spec = { type_spec } end

  local display_spec = Array.map(type_spec, function(x)
    if valid_types[x] then return valid_types[x] end
    return get_name(x)
  end)

  return setmetatable({}, {
    __call = function(_, e)
      local invalid = {}
      local i = 1

      Array.each(type_spec, function(spec)
        if not is_a(e, spec) then
          invalid[i] = display_spec[i]
          i = i + 1
        end
      end)

      if #invalid == #type_spec then
        return false,
          string.format(
            "expected %s, got %s",
            table.concat(invalid, "|"),
            get_name(e)
          )
      end

      return true
    end,
    required = table.concat(display_spec, "|"),
  })
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
          valid_types[tostring(b)] or tostring(b)
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
      if opt then optional[_k] = true end
      if _k:match "^[0-9]+$" then _k = tonumber(_k) end
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
        error(
          string.format(
            "%s: missing key: %s",
            level_name,
            dump(missing:values())
          )
        )
      end
    end)

    if not nonexistent then
      assert(
        foreign:len() == 0,
        string.format(
          "%s: unrequired table.keys: %s",
          level_name,
          dump(foreign:values())
        )
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

      if optional[display] and param == nil then return end

      if is_table(tp) then
        if is_pure_table(tp) then
          if not is_table(param) then
            _throw_error(display, "expected table, got %s", get_name(param))
          elseif not is_pure_table(param) then
            _throw_error(
              display,
              "expected pure_table, got %s",
              get_name(param)
            )
          else
            _validate2(tp, param)
          end
        elseif is_callable(tp) then
          local ok, msg = tp(param)
          if not ok then
            _throw_error(display, msg or "callable failed %s", tostring(param))
          end
        else
          if not is_table(param) then
            _throw_error(display, "expected table, got %s", get_name(param))
          end
          local ok, msg = is(tp)(param)
          if not ok then _throw_error(display, msg) end
        end
      elseif is_function(tp) then
        local ok, msg = tp(param)
        if not ok then
          _throw_error(display, msg or "callable failed %s", tostring(param))
        end
      elseif is_string(tp) then
        if not is_a(param, tp) then
          tp = valid_types[tp] or tp
          _throw_error(display, "expected %s, got %s", tp, get_name(param))
        end
      else
        local a, b = typeof(tp), typeof(param)
        assert(a == b, sprintf("%s: expected %s, got %s", display, a, b))
      end
    end)
  end

  _compare(a, b)
end

local function _validate(type_spec)
  Dict.each(type_spec, function(display, spec)
    local tp, param = unpack(spec)
    if display:match "^%?" and param == nil then return end
    display = display:gsub("^%?", "")

    if is_table(tp) then
      if is_pure_table(tp) then
        if not is_table(param) then
          _throw_error(display, "expected table, got %s", get_name(param))
        else
          _validate2(tp, param)
        end
      elseif is_callable(tp) then
        local ok, msg = tp(param)
        if not ok then
          _throw_error(display, msg or "callable failed %s", tostring(param))
        end
      else
        if not is_table(param) then
          _throw_error(display, "expected table, got %s", get_name(param))
        end
        local ok, msg = is(tp)(param)
        if not ok then _throw_error(display, msg) end
      end
    elseif is_function(tp) then
      local ok, msg = tp(param)
      if not ok then
        _throw_error(display, msg or "callable failed %s", tostring(param))
      end
    elseif is_string(tp) then
      if not is_a(param, tp) then
        tp = valid_types[tp] or tp
        _throw_error(display, "expected %s, got %s", tp, get_name(param))
      end
    else
      local a, b = typeof(tp), typeof(param)
      assert(a == b, sprintf("%s: expected %s, got %s", display, a, b))
    end
  end)
end

validate = setmetatable({}, {
  __index = function(_, display)
    return function(spec, obj) _validate { [display] = { spec, obj } } end
  end,
  __call = function (_, ...)
    _validate(...)
  end,
})
