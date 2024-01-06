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
function case.is_var(x)
  return mtget(x --[[@as table]], "type") == "case.variable"
end

--- @param name any
--- @param test? boolean|function
--- @return case.variable
function case.var(name, test)
  if is_callable(name) then
    test = name
    name = nil
  end

  if test then
    assertisa.callable(test)
  else
    test = function()
      return true
    end
  end

  return setmetatable({ name = name, test = test }, { type = "case.variable" })
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
    return (is_a(x, unpack(tps)))
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
    if not is_string(x) and not is_table(x) then
      return false
    end

    local use = is_string(x) and string.contains or dict.contains
    return use(x, unpack(args))
  end
end

function case.has(...)
  local args = { ... }

  return function(x)
    if not is_string(x) and not is_table(x) then
      return false
    elseif is_string(x) then
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
    if not is_string(x) then
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

function case.match(a, b, opts)
  opts = opts or {}
  local pre_b = opts.pre_b
  local pre_a = opts.pre_a
  local default = opts.default
  local eq = opts.eq
  local absolute = opts.absolute
  local same_size = opts.same_size
  local use_rawget = opts.rawget
  local match = opts.match
  local vars = {}
  local state = {}
  local result = state
  local cond = opts.cond

  if pre_b or pre_a then
    if pre_a then
      assertisa.callable(pre_a)
    end

    if pre_b then
      assertisa.callable(pre_b)
    end
  end

  if default then
    assertisa.callable(default)
  end

  if eq then
    assertisa.callable(eq)
  end

  if match then
    absolute = true
    cond = true
  end

  local function cmp(a_value, b_value, matched_vars)
    matched_vars = match and (matched_vars or {})
    local ok = false
    local is_var = case.is_var(b_value)

    if is_var then
      assert(match, "cannot case.var without .match")
    end

    if pre_b then
      b_value = pre_b(b_value)
    end

    if pre_a then
      a_value = pre_a(a_value)
    end

    local ok = false
    if is_var then
      if b_value.test then
        return b_value.test(a_value)
      end

      return true
    else
      if is_function(b_value) and cond then
        ok = b_value(a_value)
      elseif eq then
        ok = eq(a_value, b_value)
      else
        ok = a_value == b_value
      end
    end

    return ok
  end

  local function resolve(x)
    local optional
    x = tostring(x)
    x, optional = x:gsub("(^opt_|%?$)", "")
    x = is_number(x) or x

    if optional > 0 then
      return x, true
    end

    return x, false
  end

  local function filter_resolve(ks)
    local required = {}
    local optional = {}
    local all = {}

    for i = 1, #ks do
      local k, opt = resolve(ks[i])
      if opt then
        optional[k] = true
      else
        required[k] = true
      end

      all[#all + 1] = ks[i]
    end

    return all, required, optional
  end

  local function get(x, k)
    local elem

    if use_rawget then
      elem = rawget(x, k)
    else
      elem = x[k]
    end

    if default then
      elem = default()
    end

    return elem
  end

  local function have_same_size(p, q)
    if same_size then
      return size(p) == size(q)
    end

    return true
  end

  local function recurse(A, B, ok)
    local ks, required, optional = filter_resolve(keys(B))
    ok = defined(ok, false)
    local matched = match and {}
    local later = {}

    for i = 1, #ks do
      local k = ks[i]
      local m, n = get(A, k), get(B, k)

      if is_nil(m) then
        if required[k] and not absolute then
          ok = false
        elseif absolute then
          return false
        else
          state[k] = false
        end
      elseif case.is_var(n) then
        if not n.name then
          n.name = k
        end

        --- TODO
        if is_table(n.test) then
        end

        if not cmp(m, n) then
          return false
        else
          vars[n.name] = m
        end
      elseif is_table(n) then
        if not is_table(m) then
          if absolute then
            return false
          else
            state[k] = false
          end
        else
          state[k] = {}
          state = state[k]
          later[#later+1] = {m, n}
        end
      else
        if not cmp(m, n) then
          if absolute then
            return false
          else
            state[k] = false
          end
        else
          state[k] = true
        end
      end
    end

    for i=1, #later do
      ok = recurse(unpack(later[i]))
    end

    return true
  end

  if not have_same_size(a, b) then
    return false
  end

  if not recurse(a, b) then
    if absolute then
      return false
    end
  elseif absolute and not match then
    return true
  elseif match then
    return vars
  else
    return result
  end
end

local function switchcase(x, specs)
  local default = specs.default

  for spec, f in pairs(specs) do
    local ok

    if is_table(x) and is_table(spec) then
      ok = case.match(x, spec, { cond = true, absolute = true })
    elseif is_function(spec) then
      ok = spec(x)
    else
      ok = x == y
    end

    if ok then
      if is_boolean(ok) then
        return f(x)
      end
      return f(ok)
    end
  end

  return default(x)
end

function case:__call(x, specs)
  if specs then
    return switchcase(x, specs)
  else
    return switchcase
  end
end
