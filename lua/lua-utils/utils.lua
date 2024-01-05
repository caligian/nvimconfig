--- Stringify element
--- @overload fun(x:any): string
inspect = require "inspect"

--- @param x any
--- @param force? bool forcefully wrap the elem in a table?
--- @return table
function to_list(x, force)
  if force then
    return { x }
  elseif type(x) == "table" then
    return x
  else
    return { x }
  end
end

--- @alias dict table
--- @alias list any[]
--- @alias bool boolean
--- @alias num number
--- @alias str string
--- @alias fn function

--- Valid lua metatable keys
--- @enum
mtkeys = {
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

--- Stringify object
--- @param x any object
--- @return string
function dump(x)
  return inspect(x)
end

--- Alias for table.concat
--- @param x list
--- @param sep? string
--- @return string
function concat(x, sep)
  return table.concat(x, sep)
end

--- Alias for table.concat
--- @param x list a list
--- @param sep? string separator string
function join(x, sep)
  return table.concat(x, sep)
end

--- Stringify and print object
--- @param ... any object
function pp(...)
  local args = { ... }

  for i = 1, #args do
    print(inspect(args[i]))
  end
end

--- sprintf with stringification
--- @param fmt string string.format compatible format
--- @param ... any placeholder variables
--- @return string
function sprintf(fmt, ...)
  local args = { ... }
  for i = 1, #args do
    args[i] = type(args[i]) ~= "string" and inspect(args[i]) or args[i]
  end

  return string.format(fmt, unpack(args))
end

--- printf with stringification
--- @param fmt string string.format compatible format
--- @param ... any placeholder variables
function printf(fmt, ...)
  print(sprintf(fmt, ...))
end

--- Get metatable or metatable key
--- @param obj table
--- @param k? any a key. If not given then return metatable
--- @return any value metatable or value
function mtget(obj, k)
  if type(obj) ~= "table" then
    return
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

--- Set metatable or metatable key
--- @param obj table
--- @param k any if v is nil then set k as metatable else retrieve key
--- @param v? any value to set
--- @return any
function mtset(obj, k, v)
  if v == nil then
    return setmetatable(obj, k)
  end

  local mt = getmetatable(obj) or {}
  mt[k] = v

  return setmetatable(obj, mt)
end

--- Shallow copy a table
--- @param obj table table to copy at depth 1
--- @return table
function copy(obj)
  if type(obj) ~= "table" then
    return obj
  end

  local out = {}
  for key, value in pairs(obj) do
    out[key] = value
  end

  return out
end

--- Create a module. It is possible to set metatable keys and retrieve them. Supports tostring()
--- @return table
function module()
  local mod = {}
  local mt = { __tostring = dump, type = "module" }

  function mt:__newindex(key, value)
    if mtkeys[key] then
      mt[key] = value
    else
      rawset(self, key, value)
    end
  end

  function mt:__index(key)
    if mtkeys[key] then
      return mt[key]
    end
  end

  return setmetatable(mod, mt)
end

ns = module

--- Decorate a function
--- @param f1 function to be decorated
--- @param f2 function decorating function
--- @return function
function decorate(f1, f2)
  return function(...)
    return f2(f1(...))
  end
end

--- Apply an list of args to a function
--- @param f function
--- @param args list to apply
--- @return any
function apply(f, args)
  return f(unpack(args))
end

--- Prepend args and apply params
--- @param f function
--- @param ... list params to prepend
--- @return function
function rpartial(f, ...)
  local outer = { ... }
  return function(...)
    local inner = { ... }
    local len = #outer
    for idx, a in ipairs(outer) do
      inner[len + idx] = a
    end

    return f(unpack(inner))
  end
end

--- Append args and apply params
--- @param f function
--- @param ... list params to append
--- @return function
function partial(f, ...)
  local outer = { ... }
  return function(...)
    local inner = { ... }
    local len = #outer
    for idx, a in ipairs(inner) do
      outer[len + idx] = a
    end

    return f(unpack(outer))
  end
end

--- Return object as is
--- @param x any
--- @return any
function identity(x)
  return x
end

--- Pass an element through N functions
--- @param x any
--- @param ... fn[]
--- @return any
function thread(x, ...)
  local out = x
  local args = { ... }

  for i = 1, #args do
    local f = args[i]
    out = f(out)
  end

  return out
end

--- Get table values
--- @param t table
--- @return any[]
function values(t)
  local out = {}
  local i = 1

  for _, value in pairs(t) do
    out[i] = value
    i = i + 1
  end

  return out
end

--- Get table keys
--- @param t table
--- @param sort? boolean
--- @param cmp? fun(x:any): boolean
--- @return any[]
function keys(t, sort, cmp)
  local out = {}
  local i = 1

  for key, _ in pairs(t) do
    out[i] = key
    i = i + 1
  end

  if sort then
    table.sort(out, cmp)
  end

  return out
end

--- Is x a string?
--- @param x any
--- @return boolean,string?
function is_string(x)
  local ok = type(x) == "string"
  local msg = "expected string, got " .. type(x)

  if not ok then
    return false, msg
  end

  return true
end

--- Is x a table?
--- @param x any
--- @return boolean,string?
function is_table(x)
  local ok = type(x) == "table"

  if not ok then
    local msg = "expected table, got " .. type(x)
    return false, msg
  end

  return true
end

--- Is x a function?
--- @param x any
--- @return boolean,string?
function is_function(x)
  local ok = type(x) == "function"
  local msg = "expected function, got " .. type(x)

  if not ok then
    return false, msg
  end

  return true
end

--- Is x a userdata?
--- @param x any
--- @return boolean,string?
function is_userdata(x)
  local ok = type(x) == "userdata"

  if not ok then
    local msg = "expected userdata, got " .. type(x)
    return false, msg
  end

  return true
end

--- Is x a thread?
--- @param x any
--- @return boolean,string?
function is_thread(x)
  local ok = type(x) == "thread"
  local msg = "expected thread, got " .. type(x)

  if not ok then
    return false, msg
  end

  return true
end

--- Is x a boolean?
--- @param x any
--- @return boolean,string?
function is_boolean(x)
  local ok = type(x) == "boolean"

  if not ok then
    local msg = "expected boolean, got " .. type(x)
    return false, msg
  end

  return true
end

--- Is x a number?
--- @param x any
--- @return boolean,string?
function is_number(x)
  local ok = type(x) == "number"

  if not ok then
    local msg = "expected number, got " .. type(x)
    return false, msg
  end

  return true
end

--- Is x a function (__call is nonnil or x is a function)?
--- @param x any
--- @return boolean,string?
function is_callable(x)
  local tp = type(x)

  if tp == "function" then
    return true
  elseif tp ~= "table" then
    return false
  end

  local mt = getmetatable(x)
  if not mt then
    return false
  end

  local ok = mt.__call ~= nil
  if not ok then
    return false
  end

  return true
end

--- Is x nil
--- @param x any
--- @return boolean
function is_nil(x)
  return x == nil
end

--- Is list? Table cannot have a metatable
--- @param x any
--- @return boolean, string?
function is_list(x)
  local tp = type(x)

  if tp ~= "table" then
    return false
  end

  local ks = #keys(x)
  if ks == 0 then
    return false
  end

  local ok = ks == #x and not mtget(x, "type")
  if not ok then
    return false
  end

  return true
end

--- Is dict? Cannot have a metatable key 'type'
--- @param x any
--- @return boolean, string?
function is_dict(x)
  local tp = type(x)

  if tp ~= "table" then
    return false
  end

  local ks = #keys(x)
  if ks == 0 then
    return false
  end

  local ok = not is_list(x)
  if not ok then
    return false
  elseif mtget(x, 'type') then
    return false
  end

  return true
end

--- Is list-like?
--- @param x table
--- @return table|boolean
function listlike(x)
  if not is_table(x) then
    return false
  end
  return #keys(x) == #x and x or false
end

--- Is dict-like?
--- @param x table
--- @return table|bool
function dictlike(x)
  return is_table(x) and not listlike(x) and x or false
end

--- Is empty?
--- @param x string|list
--- @return boolean
function is_empty(x)
  if is_string(x) then
    --- @cast x string
    return #x == 0
  end

  --- @cast x list
  return #keys(x) == 0
end

--- Get value type. This checks for metatable key 'type' Also returns 'callable', 'list' and 'dict'
--- @param x any
--- @return string
function gettype(x)
  if is_table(x) then
    if is_list(x) then
      return "list"
    elseif is_dict(x) then
      return "dict"
    else
      local tp = mtget(x, "type")
      if tp then
        return tp
      elseif is_callable(x) then
        return "callable"
      else
        return "table"
      end
    end
  else
    return type(x)
  end
end

typeof = gettype

--- Is module?
--- @param x any
--- @return boolean,string?
function is_module(x)
  local ok = gettype(x) == "module"
  if not ok then
    return false
  end
  return true
end

function is_instance(x, name)
  local mt = mtget(x)

  if not mt then
    return false, "expected table with metatable, got " .. dump(x)
  end

  if not mt.type and not mt.class then
    return false, "expected class instance, got " .. dump(x)
  elseif name then
    if mt.type ~= name then
      return false, "expected class instance of type " .. name .. ", got " .. dump(x)
    end
  end

  return true
end

local function _istype(x, tp)
  local gotten = gettype(x)

  if is_function(tp) then
    local ok, msg = tp(x)
    msg = not ok and (msg or sprintf("function %s failed for %s", tostring(tp), type(x)))
    return ok, msg
  elseif tp == "classmod" then
    return is_classmod(x), "expected classmod, got " .. gotten
  elseif tp == "module" then
    return is_module(x), "expected module, got " .. gotten
  elseif type(x) == "table" and tp == "table" then
    return true
  elseif tp == "*" or tp == "any" then
    return true
  elseif tp == "list" then
    return is_list(x), "expected list, got " .. gotten
  elseif tp == "dict" then
    return is_dict(x), "expected dict, got " .. gotten
  elseif tp == "callable" then
    return is_callable(x), "expected callable, got " .. gotten
  elseif is_string(tp) then
    if tp:match "%?$" then
      tp = tp:gsub("%?$", "")
      if x == nil then
        return true
      end
    end

    x = gettype(x)
    local err = sprintf("expected %s, got %s", tp, x)

    return x == tp, err
  else
    x = gettype(x)
    tp = gettype(tp)
    local err = sprintf("expected %s, got %s", tp, x)

    return x == tp, err
  end
end

--- Is object of type X?
--- @param x any
--- @param tp? string|function|table
--- @return (boolean|function), string?
function is_type(x, tp)
  if is_nil(tp) then
    return function(_x)
      return (_istype(_x, x))
    end
  end

  return (_istype(x, tp))
end

local function _istypes(x, ...)
  local args = { ... }
  local failed_ctr = 0
  local err = {}

  for i = 1, #args do
    res = is_type(x, args[i])

    if not res then
      failed_ctr = failed_ctr + 1
      err[#err + 1] = not is_string(args[i]) and typeof(args[i]) or args[i]
    end
  end

  if failed_ctr < #args then
    return true
  end

  local err_s = "[" .. concat(err, ", ") .. "]"
  err_s = sprintf("expected any of %s, got %s", err_s, dump(x))

  return false, err_s
end

--- Check if X is any of types ...
--- @param x any
--- @param ... string|function|table
--- @see istype
--- @return boolean, string?
function is_types(x, ...)
  return (_istypes(x, ...))
end

--- Return a function that checks union of types ...
--- @param ... string|function|table
--- @return fun(x): boolean, string?
function union(...)
  local args = { ... }

  return function(x)
    local res, msg = _istypes(x, unpack(args))

    if res then
      return true
    end

    return false, msg
  end
end

--- Check if X if of type Y
--- > isa.number(1)
--- > is_a(1, 'number')
--- > is_a('a', function(x) return x == 'a' end)
--- @overload fun(x:any, tp:string|function|table, assert?:boolean): boolean,string
isa = setmetatable({}, {
  __index = function(self, key)
    return function(x)
      return self(x, key)
    end
  end,
  __call = function(_, x, tp, assert_type)
    if tp == "*" or tp == "any" then
      return true
    end

    if tp == "table" and type(x) == "table" then
      return true
    end

    local res, msg = _istype(x, tp)

    if not res and assert_type then
      error(msg)
    elseif not res then
      return false, msg
    end

    return true
  end,
})

is_a = isa

--- Assert X is of type Y else raise error
--- @param x any
--- @param tp any
--- @return bool,str
function asserttype(x, tp)
  return is_a(x, tp, true)
end

assertisa = mtset({}, {
  __index = function(self, key)
    local use

    if is_string(key) then
      local g = _G["is" .. key] or _G["is_" .. key]
      if g then
        use = function(obj)
          if not g(obj) then
            error("expected " .. key .. ", got " .. type(obj))
          end

          return obj
        end
      end
    end

    use = function(obj)
      assert(is_a(obj, key))
      return obj
    end

    if is_string(key) then
      rawset(self, key, use)
    end

    return use
  end,
  __call = function(self, obj, tp)
    self[tp](obj)

    return obj
  end,
})

--- Deep copy table
--- @param x table
--- @param callback? fun(x): any
--- @param cache? dict lookup table
--- @param new? dict destination table
--- @return table
function deepcopy(x, callback, cache, new)
  if type(x) ~= "table" then
    return x
  end

  cache = cache or {}
  new = new or {}
  local current = new

  local function walk(tbl)
    if cache[tbl] then
      return
    else
      cache[tbl] = true
    end

    for key, value in pairs(tbl) do
      if type(value) == "table" and not cache[tbl] then
        current[key] = {}
        current = current[key]
        deepcopy(value, callback, cache, new)
      elseif callback then
        current[key] = callback(value)
      else
        current[key] = value
      end
    end
  end

  walk(x)

  return new
end

--- if X == nil then return Y else Z
--- @param a any
--- @param ret any returned when a is nil
--- @param orelse any returned when a is not nil
--- @return any
function ifnil(a, ret, orelse)
  if a == nil then
    return ret
  else
    return orelse
  end
end

--- if X ~= nil then return Y else Z
--- @param a any
--- @param ret any returned when a is not nil
--- @param orelse any returned when a is nil
--- @return any
function unlessnil(a, ret, orelse)
  if a == nil then
    return ret
  else
    return orelse
  end
end

--- @param test boolean
--- @param message str
--- @param orelse? any
--- @return any value return if test fails
function assertunless(test, message, orelse)
  if test then
    error(message)
  end

  return orelse
end

--- Return length of string|non-lists
--- @param x string|table
--- @return integer
function size(x)
  if is_string(x) then
    return #x
  end

  --- @cast x list
  return #keys(x)
end

--- Return length of string|lists
--- @param x string|table
--- @return integer
function length(x)
  return #x
end

--- Similar to mtset
--- @param x table
--- @param key any if table then treat `key` as kv pairs else set `value` for `key`
--- @param value? any
--- @return any
function overload(x, key, value)
  if is_table(key) then
    for k, v in pairs(key) do
      mtset(x, k, v)
    end
  else
    mtset(x, key, value)
  end

  return x
end

--- Get object attribute via a function
--- > map({{a=1}, {a=10}}, getter('a', false))
--- @param key any
--- @param default? any value to return in case of absence
--- @return fun(x:table): any
function getter(key, default)
  return function(x)
    if x[key] == nil then
      return default
    end
    return x[key]
  end
end

--- Set object attribute in a mapping function
--- > each({{}, {}}, setter('a', false))
--- @param key any
--- @param value any value to set
--- @return fun(x:table): any
function setter(key, value)
  return function(x)
    x[key] = value
    return x
  end
end

--- X == nil?
--- @param x any
--- @param orelse? any
--- @return any result if X is nonnil otherwise return `orelse`
function defined(x, orelse)
  if x ~= nil then
    return x
  else
    return orelse
  end
end

function is_class(self)
  local mt = mtget(self)
  if mt.type and mt.class then
    return true
  end

  return false
end

function is_classmod(self)
  return is_table(self) and mtget(self, "type") == "classmod" and self or false
end

function is_instance(self, other)
  if not is_table(self) or not is_table(other) then
    return false
  elseif is_classmod(other) or is_class(other) then
    return false
  elseif is_classmod(self) or is_class(self) then
    return false
  else
    return self.modname() == other.modname()
  end
end

function class(name, static)
	static = static or {}

  if not static[1] then
    for i=1,#static do
      static[static[i]] = true
      static[i] = nil
    end
  end

  if not is_string(name) then
    error("expected string, got " .. type(name))
  end

  local mod = {}
  local modmt = { type = "classmod", __tostring = dump }
  local classmt = { type = name, __tostring = dump }

  setmetatable(mod, modmt)

  function modmt:__call(...)
    local obj = mtset({}, classmt)
    static = static or {}

    for key, value in pairs(self) do
      if not static[key] then
        obj[key] = value
      end
    end

    local init = rawget(mod, "init")
    if init then
      return init(obj, ...)
    end

    return obj
  end

  function modmt:__newindex(key, value)
    if mtkeys[key] then
      modmt[key] = value
      classmt[key] = value
    else
      rawset(self, key, value)
    end
  end

  modmt.__index = modmt
  classmt.__index = classmt

  function mod.is_a(self)
    if not is_table(self) then
      return false
    end

    return mtget(self, "type") == name and self or false
  end

  function mod.assertisa(self)
    if not mod.is_a(self) then
      error("expected " .. name .. ", got " .. type(self))
    end

    return self
  end

  function mod:include(other)
    if not is_table(other) then
      return
    end

    for key, value in pairs(other) do
      self[key] = value
    end

    return self
  end

  function mod.classmod()
    return mod
  end

  function mod.modname()
    return name
  end

  return mod
end

function is_literal(x)
  return is_string(x) or is_number(x) or is_boolean(x)
end

function ref(x)
  if is_nil(x) then
    return x
  end

  if not is_table(x) then
    if is_literal(x) then
      return x
    else
      return is_string(x)
    end
  end

  local mt = mtget(x)
  if not mt then
    return is_string(x)
  end

  local tostring = rawget(mt, "__tostring")
  rawset(mt, "__tostring", nil)
  local id = tostring(x)
  rawset(mt, "__tostring", tostring)

  return id
end

function sameref(x, y)
  return ref(x) == ref(y)
end
