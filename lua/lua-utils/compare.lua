require "lua-utils.table"
require "lua-utils.Set"

--- @class case
case = case or module "case"

--- Contains all metatables created
metatables = metatables or {}

--- @class case.variable
--- @field name any
--- @field test boolean|function

--- @param x any
--- @return boolean
function case.isvar(x)
  return mtget(x --[[@as table]], "type")
    == "case.variable"
end

--- @param name any
--- @param test boolean|function
--- @return case.variable
function case.var(name, test)
  return setmetatable(
    { name = name, test = test },
    { type = "case.variable" }
  )
end

--- Is b greater than x
--- @param b any
--- @return fun(x): boolean
function case.ne(b)
  return function(a)
    return a ~= b
  end
end

--- Is b equal to x
--- @param b any
--- @return fun(x): boolean
function case.eq(b)
  return function(a)
    return a == b
  end
end

--- Is x of type Y, Z, ...?
--- @param ... string|table|function
--- @return fun(x): boolean
function case.type(...)
  local tps = { ... }
  return function(x)
    return (isa(x, unpack(tps)))
  end
end

--- Assert some condition
--- @param test fun(x):any
--- @param msg str failure message
--- @return fun(x): boolean
function case.assert(test, msg)
  return function(x)
    assert(test(x), msg)
    return true
  end
end

--- Does X contains ...
--- @param ... any
function case.contains(...)
  local args = { ... }

  return function(x)
    if not isstring(x) and not istable(x) then
      return false
    end

    local use = isstring(x) and string.contains
      or dict.contains
    return use(x, unpack(args))
  end
end

function case.has(...)
  local args = { ... }

  return function(x)
    if not isstring(x) and not istable(x) then
      return false
    elseif isstring(x) then
      return string.contains(x, unpack(args))
    end

    return list.all(args, function(a)
      return x[a] ~= nil
    end)
  end
end

function case.all(...)
  local fns = { ... }
  local n = #fns

  return function(x)
    for i = 1, n do
      if not fns[i](x) then
        return false
      end
    end

    return true
  end
end

function case.some(...)
  local fns = { ... }
  local n = #fns

  return function(x)
    for i = 1, n do
      if fns[i](x) then
        return true
      end
    end
  end
end

function case.pred(...)
  local fns = { ... }
  local n = #fns

  return function(x)
    local ok = 0
    for i = 1, n do
      ok = fns[i](x) and (ok + 1) or ok
    end

    return ok == n
  end
end

function case.sizelt(n)
  return function(x)
    return #x < n
  end
end

function case.sizegt(n)
  return function(x)
    return #x > n
  end
end

function case.sizele(n)
  return function(x)
    return #x <= n
  end
end

function case.sizege(n)
  return function(x)
    return #x >= n
  end
end

function case.size(n)
  return function(x)
    return #x == n
  end
end

function case.re(...)
  local args = { ... }

  return function(x)
    if not isstring(x) then
      return
    end

    for i = 1, #args do
      if string.match(x, args[i]) then
        return true
      end
    end
  end
end

function case.lt(b)
  return function(x)
    return x < b
  end
end

function case.gt(b)
  return function(x)
    return x > b
  end
end

function case.le(b)
  return function(x)
    return x <= b
  end
end

function case.ge(b)
  return function(x)
    return x >= b
  end
end

function dict.compare(a, b, opts)
  opts = opts and copy(opts) or {}
  opts.state = opts.state or {}
  opts._state = opts._state or opts.state
  local pre_b = opts.pre_b
  local pre_a = opts.pre_a
  local eq = opts.eq
  local absolute = opts.absolute
  local same_size = opts.same_size
  local state = opts.state
  local match = opts.match
  local vars = {}

  if match then
    absolute = true
  end

  if cond and eq then
    error "cannot use .cond and .eq together"
  end

  if (pre_a or pre_a) and not cond then
    error "cannot use .pre_a or .pre_b without .cond"
  end

  local function _cmp(key, a_value, value, ok)
    local a_value_is_nil = isnil(a_value)
    local is_var = case.isvar(value)

    if is_var then
      assert(match, "cannot case.var without .match")
    end

    value = pre_b and pre_b(value) or value
    a_value = (
      pre_a
      and not a_value_is_nil
      and pre_a(a_value)
    ) or a_value

    if not a_value_is_nil then
      if is_var then
        if isfunction(value.test) then
          ok = value.test(a_value)
        elseif value.test or value.test == nil then
          ok = true
        end

        if ok then
          vars[value.name] = a_value
        end
      else
        if isfunction(value) then
          ok = value(a_value)
        elseif eq then
          ok = eq(a_value, value)
        else
          ok = a_value == value
        end

        if not match then
          state[key] = ok
        end
      end
    end

    return ok
  end

  local function resolve(x)
    x = tostring(x):gsub("%?$", "")
    return tonumber(x) or x
  end

  local function _recurse(A, B)
    local ks = keys(B)
    local optional = filter(ks, resolve)
    ks = map(ks, resolve)

    for i = 1, #ks do
      local k = ks[i]
      local m, n = (A and A[k]), (B[k] or B[k .. "?"])

      if m == nil and optional[k] then
        ok = true
      elseif
        istable(m)
        and istable(n)
        and not case.isvar(n)
      then
        if same_size and size(m) ~= size(n) then
          return false
        end

        state[k] = {}
        state = state[k]
        opts.state = state
        init = false
        return _recurse(m, n)
      else
        local ok = _cmp(k, m, n)
        if not ok and absolute then
          return false
        end
      end
    end

    return true
  end

  if same_size and size(a) ~= size(b) then
    return false
  end

  local ok = _recurse(a, b)
  if absolute and not ok then
    return false
  elseif not match then
    return opts._state
  elseif ok then
    return vars
  end

  return false
end

function dict.eq(a, b, opts)
  local a_is_table = istable(a)
  local b_is_table = istable(b)

  if a_is_table and b_is_table then
    opts = opts or {}
    opts.absolute = true
    return dict.compare(a, b, opts)
  elseif a_is_table or b_is_table then
    return false
  else
    return a == b
  end
end

function dict.ne(a, b, opts)
  return not dict.eq(a, b, opts)
end

function case:__call(x, specs)
  local function _case(SPECS)
    specs = SPECS
    local default = specs.default

    for spec, f in pairs(specs) do
      local ok

      if istable(x) and istable(spec) then
        ok = dict.compare(
          x,
          spec,
          { cond = true, absolute = true }
        )
      elseif isfunction(spec) then
        ok = spec(x)
      else
        ok = x == y
      end

      if ok then
        if isboolean(ok) then
          return f(x)
        end
        return f(ok)
      end
    end

    return default(x)
  end

  if specs then
    return _case(specs)
  else
    return _case
  end
end

function defmulti(specs)
  return function(...)
    local args = { ... }

    for key, value in pairs(specs) do
      if isstring(key) then
        key = union(key)
      end

      if isfunction(key) then
        if key(args) then
          return value(unpack(args))
        end
      elseif case.isvar(key) then
        error "cannot use case.var object for matching"
      else
        local ok = compare(args, key, {
          cond = true,
          absolute = true,
          pre_b = function(x)
            if isstring(x) then
              return union(x)
            end

            return x
          end,
        })

        if ok then
          return value(unpack(args))
        end
      end
    end

    error("no signature matching args " .. dump { ... })
  end
end

function isliteral(x)
  return isstring(x) or isnumber(x) or isboolean(x)
end

function ref(x)
  if isnil(x) then
    return x
  end

  if not istable(x) then
    if isliteral(x) then
      return x
    else
      return tostring(x)
    end
  end

  local mt = mtget(x)
  if not mt then
    return tostring(x)
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

function addmetatable(x, mt)
  if x == nil then
    mt = {}
    metatables[mt] = mt

    return mt
  end

  local save = mt

  if mt then
    local x_mt = mtget(x)
    if not x_mt or x_mt ~= mt then
      mtset(x, mt)
    end
  else
    save = mtget(x)
    if not save then
      save = {}
      mtset(x, save)
    end
  end

  metatables[save] = save
  return save
end

local function _literalcompare(
  x,
  y,
  get_state,
  _state,
  _fullstate
)
  local state
  if get_state then
    state = _state or {}
    fullstate = _fullstate or state
  end

  for key, value in pairs(y) do
    local x_value = rawget(x, key)
    local y_value = value

    if istable(y_value) and istable(x_value) then
      if state then
        state[key] = {}
        state = state[key]
      end

      return _literalcompare(
        x_value,
        y_value,
        true,
        state,
        fullstate
      )
    elseif x_value == nil or y_value ~= x_value then
      if get_state then
        return false, fullstate
      else
        return false
      end
    elseif get_state then
      state[key] = true
    end
  end

  if get_state then
    return true, fullstate
  end

  return true
end

function literalcompare(x, y, get_state)
  return _literalcompare(x, y, get_state)
end

local function _claim(x, y, levelname)
  if x == nil and levelname:match "%?$" then
    return true
  end

  levelname = levelname or "<base>"
  if isfunction(y) or isstring(y) then
    local ok, msg
    y = isstring(y) and union(y) or y
    ok, msg = y(x)

    if not ok then
      msg = msg or ""
      msg = levelname
        .. (
          #msg > 0 and (": " .. msg)
          or ": callable failed for " .. dump(x)
        )
      error(msg)
    else
      return
    end
  end

  if not istable(y) then
    error(
      levelname
        .. ": expected table|string|function for spec, got "
        .. y
    )
  end

  local ykeys = keys(y)
  levelname = y.__name or levelname
  local extra = y.__extra
  y.__name = nil
  y.__extra = nil

  local function resolve(X)
    X = isstring(X) and X:match "%?$" and X:sub(1, #X - 1)
      or X
    return tonumber(X) or X
  end

  local optional = list.filter(ykeys, function(X)
    return (tostring(X):match "%?$")
      or (X == "__extra" or X == "__name")
  end, resolve)

  optional = Set(optional)
  ykeys = Set(list.map(ykeys, resolve))
  local xkeys = Set(keys(x))
  local required = ykeys - optional
  local extraks = xkeys - ykeys
  local missing = (required - xkeys)
    / function(key)
      if
        x[key] == nil and optional[key] or key == "__name"
      then
        return false
      end

      return true
    end

  if not extra then
    if size(extraks) > 0 then
      error(
        levelname
          .. ": found extra keys: "
          .. join(keys(extraks), ",")
      )
    end
  end

  if size(missing) > 0 then
    error(
      levelname
        .. ": missing keys: "
        .. join(keys(missing), ",")
    )
  end

  for key, value in pairs(y) do
    local k = resolve(key)
    local a, b = x[k], value

    if a == nil and optional[k] then
    elseif istable(a) and istable(b) then
      b.__name = levelname .. "." .. key
      _claim(a, b)
    elseif istable(b) then
      error(
        levelname
          .. "."
          .. key
          .. ": expected table, got "
          .. dump(a)
      )
    else
      asserttype(b, union("string", "function"))

      b = isstring(b) and union(b) or b
      local ok, msg = b(a)

      if not ok then
        msg = msg or ""
        msg = levelname
          .. "."
          .. key
          .. (
            #msg > 0 and (": " .. msg)
            or ": callable failed"
          )
        error(msg)
      end
    end
  end
end

function params(specs)
  for key, value in pairs(specs) do
    assertisa(value, function(x)
      return islist(x) and #x <= 2,
        "expected at least 1 item long list, got " .. dump(
          x
        )
    end)

    local spec = value[1]
    local x = value[2]
    local name = key

    _claim(x, spec, name)
  end
end

---- Pattern matching
--- > local print_name = defmulti {
--- >   [] = function(name, id)
--- >     return { name = name, id = id }
--- >   end,
--- >   [{ { a = { is_string, case.var("age", case.contains "2") } } }] = function(x)
--- >     return x
--- >   end,
--- > }
--- >
--- > pp(
--- >   compare(
--- >     { a = { 1, 2 } },
--- >     { a = { is_number, case.var("2", is_number) } },
--- >     { cond = true, absolute = true, match = true }
--- >   )
--- > )
--- >
--- > pp(print_name { a = { "user", "23" } })

