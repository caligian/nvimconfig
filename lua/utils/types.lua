-- require "utils.Set"
require "utils.Array"
require "utils.Dict"

valid_types = {
  number = "number",
  n = "number",

  string = "string",
  s = "string",

  ["function"] = "callable",
  f = "callable",
  callable = 'callable',

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

function is_pure_table(x)
  if type(x) == "table" and not is_class(x)  then
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
  local get_name = function(x)
    if is_class(x) then
      return {name=x:get_name(), type='class'}
    elseif is_table(x) then
      local mt = getmetatable(x)
      if not mt then return {type='table'} end
			if mt.type and mt.name then
				return {name = mt.name, type = mt.type}
			elseif mt.type then
				return {type=mt.type}
			else
				return {type='table'}
			end
		else
			return {type=typeof(x)} 
		end
	end

	local spec, param = y, x
	local ok, msg
	local _spec, _param = get_name(spec), get_name(param)
	local msg_spec, msg_param

	if _spec.name and _spec.type then
		msg_spec = _spec.type .. ':' .. _spec.name
	elseif _spec.type then
		msg_spec = _spec.type
	end

	if _param.name and _param.type then
		msg_param = _param.type .. ':' .. _param.name
	elseif _param.type then
		msg_param = _param.type
	end

  if _spec.type == 'function' or _spec.type == 'callable' then
		ok, msg = spec(param)
		msg = msg or 'callable failed ' .. tostring(param)
	elseif _spec.type == 'string' then
		if spec == 'pure_table' then
			ok = is_pure_table(param)
			msg = 'expected pure_table, got ' .. msg_param
    elseif spec == 'callable' then
      ok = is_callable(param)
			msg = 'expected callable, got ' .. msg_param
		else
			ok = spec == _param.type
		end
		msg_spec = spec
	elseif _spec.type == 'class' or _spec.type == 'type' then
		if _spec.type == 'class' then
			ok = _param.type == 'class'
		else
			ok = _param.type == 'type'
		end
	else
		ok = _param.type == _spec.type
  end

	if not msg then
		msg = 'expected ' .. msg_spec .. ', got ' .. msg_param
	end

	if not ok then return false, msg end
	return true
end

is_a = setmetatable({}, {
  __index = function(self, spec)
    return function(obj)
      local ok, msg = _is_a(obj, valid_types[spec] or spec)
      return ok, msg
    end
  end,
  __call = function(_, obj, spec)
    local ok, msg = _is_a(obj, valid_types[spec] or spec)
    return ok, msg
  end,
})

function is(type_spec)
  local function get_name(x)
    if not is_table(x) then
      return typeof(x)
    end

    local tp = mtget(x, "type")
    local name = mtget(x, "name")
    if tp and name then
      return sprintf("%s:%s", tp, name)
    else
      return tp
    end
  end

  if not is_pure_table(type_spec) then
    type_spec = { type_spec }
  end

  type_spec = Array.map(type_spec, function(x)
    if valid_types[x] then
      return valid_types[x]
    end
    return x
  end)

  return function(e)
    local _, msg
    local n = #type_spec
    local failed = 0

    for i=1, n do
      _, msg = is_a(e, type_spec[i])
      if not _ then
        failed = failed + 1
      end
    end

    if failed == n then
      return false, msg
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

    if is_a(tp, 'string') then
      tp = valid_types[tp] or tp
    end

    if is_pure_table(tp) then 
      tp.__table = display 
      _validate2(tp, param)
    else
      local ok, msg = is_a(param, tp)
      assert(ok, msg)
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
      validate.param(is(spec), param)
      return param
    end
  end

  validate.param(is(spec), param)

  return param
end

struct = function(spec)
  validate.spec("table", spec)

  spec.__nonexistent = false
	local mt = {type='struct'}
	local st = setmetatable({ mandatory = {}, optional = {}, spec = spec }, mt)

	for key, tp in pairs(spec) do
		if not key:match('__nonexistent') or key:match('__table') then
			local is_opt = key:match('^%?') or key:match('^opt_')
			key = key:gsub('^%?', '')
			key = key:gsub('^opt_', '')
			if is_opt then
				st.optional[key] = tp
			else
				st.mandatory[key] = tp
			end
		end
	end

	mt.__call = function(self, t)
		validate.param(self.spec, t)
		return t
	end

	return st
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

