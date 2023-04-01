require 'utils.set'
require 'utils.table'

Types = Types
  or {
    types = {
      pure_table = "pure_table",
      number = "number",
      string = "string",
      table = "table",
      thread = "thread",
      ["nil"] = "nil",
      [vim.NIL] = "nil",
      ["function"] = "function",
      callable = "callable",
      userdata = "userdata",
      boolean = "boolean",
      type = "type",
    },
  }

function Types.is_number(x) return type(x) == "number" end

function Types.is_string(x) return type(x) == "string" end

function Types.is_userdata(x) return type(x) == "userdata" end

function Types.is_table(x) return type(x) == "table" end

function Types.is_thread(x) return type(x) == "thread" end

function Types.is_boolean(x) return type(x) == "boolean" end

function Types.is_function(x) return type(x) == "function" end

function Types.is_nil(x) return x == nil end

function Types.is_type(x)
  if not Types.is_table(x) then return false end
  local mt = getmetatable(x) or {}
  return mt.type == 'type'
end

function Types.is_module(x)
  if not Types.is_table(x) then return false end
  local mt = getmetatable(x) or {}
  return mt.type == "module"
end

function Types.is_callable(x)
  if Types.is_function(x) then return true end
  if not Types.is_table(x) then return false end
  local mt = getmetatable(x) or {}
  return Types.is_function(mt.__call)
end

function Types.is_pure_table(x)
  if not Types.is_table(x) then return false end
  if getmetatable(x) then return false end

  return true
end

function Types.type_of(x)
  if Types.is_module(x) then
    return "module"
  elseif Types.is_callable(x) then
    return "callable"
  elseif Types.is_nil(x) then
    return "nil"
  elseif Types.is_pure_table(x) then
    return "pure_table"
  elseif Types.is_type(x) then
    return 'type'
  elseif Types.is_table(x) then
    local mt = getmetatable(x) or {}
    return mt.type or "table"
  end
  return Types.types[type(x)] or false
end

function Types.name_of(x)
  if not Types.is_type(x) then return end
  return getmetatable(x).name
end

function Types.is_a(x, y)
  if x == nil then return y == nil end
  if x == y then return true end
  if Types.type_of(x) == y then return true end

  local t1, t2 = Types.type_of(x), Types.type_of(y)
  if t1 ~= t2 then return false end
  if t1 ~= "table" and t2 ~= "table" then return true end

  return Types.type_of(x) == Types.type_of(y)
end

function Types.assert_is_a(x, y)
  assert(Types.is_a(x, y), tostring(x) .. " expected, got " .. tostring(y))
  return x, y
end

function Types.assert_same_type(x, y)
  assert(
    Types.same_type(x, y),
    Types.type_of(x) .. " expected, got " .. Types.type_of(y)
  )
  return x, y
end

function Types.assert_has_mt(t)
  assert(getmetatable(t), tostring(t) .. ' does not have a metatable')
  return t
end

function Types.add(x)
  Types.assert_is_a(x, 'table')
  Types.assert_has_mt(x)

  local mt = getmetatable(x)
  assert(mt.type, 'type missing in ' .. tostring(x))
  Types.types[mt.type] = mt.type
  return x
end

function Types.is(type_spec)
  if not Types.is_table(type_spec) then type_spec = {type_spec} end

  return setmetatable({}, {
    __call = function(_, e)
      local invalid = {}
      for _, t in ipairs(type_spec) do
        if not Types.is_a(e, t) then invalid[#invalid + 1] = t end
      end

      if #invalid == #type_spec then
        return false,
          string.format(
            "expected %s, got %s",
            table.concat(invalid, "|"),
            tostring(Types.type_of(e))
          )
      end

      return true
    end,
    required = table.concat(type_spec, "|"),
  })
end

local function _throw_error(display, fmt, ...)
  error(display .. ': ' .. sprintf(fmt, ...))
end

local function _validate2(a, b)
  opts = opts or {}

  local function _compare(a, b)
    local nonexistent = a.__nonexistent == nil and true or a.__nonexistent
    local level_name = a.__table or tostring(a)
    a.__nonexistent = nil
    a.__table = nil
    local optional = {}
    local ks_a = table.keys(a)
    local ks_b = table.keys(b)

    table.ieach(ks_a, function(idx, k)
      k = tostring(k)
      local opt = k:match "^%?"
      local _k = k:gsub("^%?", "")
      if opt then optional[_k] = true end
      if _k:match "^[0-9]+$" then _k = tonumber(_k) end
      ks_a[idx] = _k
    end)

    ks_a = Set(ks_a)
    ks_b = Set(ks_b)
    local common = ks_a:intersection(ks_b)
    local missing = ks_a:difference(ks_b)
    local foreign = ks_b:difference(ks_a)

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

    table.each(common:values(), function(key)
      display = key:gsub("^%?", "")
      local tp, param
      if optional[display] then
        tp = a['?' .. display]
      else
        tp = a[display]
      end
      param = b[display]

      if optional[display] and param == nil then return end

      if Types.is_callable(tp) then
        local ok, msg = tp(param)
        if not ok then
          if msg then
            _throw_error(display, msg)
          else
            _throw_error(display, 'callable failed %s', tostring(param))
          end
        end
      elseif Types.is_pure_table(tp) then
        tp.__table = display
        _compare(tp, param)
      elseif Types.is_string(tp) then
        if not Types.is_a(param, tp) then
          _throw_error(display, 'expected %s, got %s', tp, tostring(param))
        end
      else
        local m, n = Types.type_of(tp), Types.type_of(param)
        assert(m == n, sprintf("%s: expected %s, got %s", display, m, n))
      end
    end)
  end

  _compare(a, b)
end

local function _validate(type_spec)
  table.teach(type_spec, function(display, spec)
    local tp, param = unpack(spec)
    if display:match "^%?" and param == nil then return end
    display = display:gsub("^%?", "")

    if Types.is_callable(tp) then
      local ok, msg = tp(param)
      if not ok then
        _throw_error(display, msg or "callable failed " .. param)
      end
    elseif Types.is_pure_table(tp) then
      if not Types.is_table(param) then
        _throw_error(display, 'expected table, got ', tostring(param))
      else
        _validate2(tp, param)
      end
    elseif Types.is_string(tp) then
      if not Types.is_a(param, tp) then
        _throw_error(display,  "expected %s, got %s", tp, tostring(param))
      end
    else
      local a, b = Types.type_of(tp), Types.type_of(param)
      assert(a == b, sprintf("%s: expected %s, got %s", display, a, b))
    end
  end)
end
Types.validate = _validate

local function create_test(test)
  return function (x)
    if Types.type_of(test) == 'callable' then
      return test(x)
    end

    for _, check in ipairs(test) do
      local success = false
      if Types.is_callable(check) then
        success = check(x)
      else
        success = Types.is_a(x, check)
      end
      if success then
        return true
      end
    end
    return false
  end
end

function Types.new(name, test)
  local self = {}
  local mt = {}
  mt.type = 'type'
  mt.name = name
  mt.__newindex = function (self, k, v)
    rawset(self, k, function (obj, ...)
      Types.validate {obj = {test, obj}}
      return v(obj, ...)
    end)
  end

  return setmetatable(self, mt)
end

function Types.defun(f, spec)
  return function (obj, ...)
    Types.validate {obj={spec, obj}}
    return f(obj, ...)
  end
end
