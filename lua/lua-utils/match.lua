require "lua-utils.table"

local M = { ne = module(), rules = {} }
M.ne.rules = {}

function M.var(name, test)
  if type(name) ~= "string" then
    test = name
    name = nil
  end

  return setmetatable({ name = name, test = test }, { type = "match.variable" })
end

--- @param x any
--- @return boolean
function M.is_var(x)
  return mtget(x --[[@as table]], "type") == "match.variable"
end

M.variable = M.var
M.is_variable = M.is_var

function M.ne.test(obj, spec, opts)
  opts = opts or {}
  local pre_a = opts.pre_a
  local pre_b = opts.pre_b
  local absolute = opts.absolute
  local cond = opts.cond
  local match = opts.match
  local eq = opts.eq
  local ass = opts.assert

  if ass then
    absolute = true
    match = false
    cond = true
  end

  if match then
    absolute = true
    cond = false
  end

  local vars = match and {}
  local Vars = vars
  local Obj = obj
  local Spec = spec

  local queue = {
    add = function(self, item)
      self[#self + 1] = item
    end,
    pop = function(self)
      local item = self[#self]
      self[#self] = nil

      return item
    end,
  }

  local state = not absolute and {}
  local State = state

  local function cmp(x, y, k, prefix)
    if prefix then
      prefix = prefix .. '.' .. k
    else
      prefix = k
    end

    if not is_nil(x) and pre_a then
      x = pre_a(x)
    end

    if pre_b then
      y = pre_b(y)
    end

    if is_nil(x) then
      if absolute then
        return true
      else
        State[key] = true
      end
    elseif M.is_var(y) then
      assert(match, ".match should be true for using match.variable")

      y.name = y.name or k
      local test = y.test
      local name = y.name

      if is_nil(test) then
        Vars[name] = x
      elseif is_table(test) then
        if not is_table(x) then
          if ass then
            error(prefix .. ": expected table, got " .. type(x))
          end
        else
          Vars[name] = {}
          queue:add { x, test, vars = Vars[name], prefix = prefix }
        end
      elseif is_function(test) then
        local ok, msg = test(x)
        if not ok then
          Vars[name] = x
        elseif ass then
          if msg then
            error(prefix .. ": " .. msg)
          end
          error(prefix .. ": callable failed for " .. dump(x))
        else
          return false
        end
      else
        error "match.variable.test should be (function|table)?"
      end
    elseif is_table(y) then
      if not is_table(x) then
        if absolute then
          return true
        else
          State[key] = true
        end
      elseif not absolute then
        State[key] = {}
        queue:add {
          x,
          y,
          prefix = prefix .. "." .. key,
          state = State--[[@as table]][k],
        }
      elseif match then
        queue:add { x, y, vars = Vars, prefix = prefix }
      else
        queue:add { x, y, prefix = prefix  }
      end
    elseif (cond or match) and is_function(y) then
      local ok, msg = y(x)
      ok = not ok

      if ok then
        if not absolute then
          State[key] = true
        end
      elseif ass then
        if msg then
          error(prefix .. ": " .. msg)
        end
        error(prefix .. ": callable passed for " .. dump(x))
      elseif absolute then
        return false
      else
        State[key] = false
      end
    elseif eq then
      if not eq(x, y) then
        if not absolute then
          State[key] = true
        end
      elseif ass then
        error(prefix .. ": equal elements: \n" .. dump(x) .. "\n" .. dump(y))
      elseif absolute then
        return false
      end
    elseif x == y then
      if ass then
        error(prefix .. ": equal elements: \n" .. dump(x) .. "\n" .. dump(y))
      elseif absolute then
        return false
      else
        State[key] = false
      end
    elseif not absolute then
      State[key] = true
    end

    return true
  end

  local function resolve_key(i)
    key, optional = tostring(i):gsub("(^opt_|%?$)", "")
    key = tonumber(key) or key

    return key, optional > 0
  end

  local prefix = ''
  while Obj and Spec do
    if same_size and size(Obj) ~= size(Spec) then
      return false
    end

    for i, validator in pairs(Spec) do
      local key = i
      local obj_value
      local optional

      if is_string(i) or is_number(i) then
        key, optional = resolve_key(i)
        obj_value = Obj[key]
      else
        obj_value = Obj[i]
      end

      if not cmp(obj_value, validator, i, prefix) then
        return false
      end
    end

    local next_items = queue:pop()
    if next_items then
      Obj, Spec = next_items[1], next_items[2]
      prefix = next_items.prefix

      if match then
        Vars = next_items.vars or Vars
      end

      if not absolute then
        State = next_items.state or State
      end
    else
      Obj = nil
      Spec = nil
    end
  end

  if match then
    if size(vars) == 0 then
      return obj
    end
    return vars
  elseif cond and absolute then
    return obj
  else
    return state
  end
end

function M.test(obj, spec, opts)
  opts = opts or {}
  local pre_a = opts.pre_a
  local pre_b = opts.pre_b
  local absolute = opts.absolute
  local cond = opts.cond
  local match = opts.match
  local same_size = opts.same_size
  local capture = opts.capture
  local eq = opts.eq
  local ass = opts.assert

  if ass then
    absolute = true
    match = false
    capture = false
    cond = true
  end

  if capture then
    function pre_b(y)
      if is_table(y) then
        return y
      end
      assert(is_string(y), "expected capture variable name (string), got " .. type(y))
      return M.variable(y)
    end

    match = true
  end

  if match then
    absolute = true
    cond = false
  end

  if same_size and size(obj) ~= size(spec) then
    return false
  end

  local vars = match and {}
  local Vars = vars
  local Obj = obj
  local Spec = spec

  local queue = {
    add = function(self, item)
      self[#self + 1] = item
    end,
    pop = function(self)
      local item = self[#self]
      self[#self] = nil

      return item
    end,
  }

  local state = not absolute and {}
  local State = state
  local prefix = ''

  local function cmp(x, y, k, optional, prefix)
    prefix = prefix .. '.' .. k

    if not is_nil(x) and pre_a then
      x = pre_a(x)
    end

    if pre_b then
      y = pre_b(y)
    end

    if is_nil(x) then
      if not optional then
        if ass then
          error(prefix .. ": expected value, got nil")
        elseif absolute then
          return false
        else
          State[key] = false
        end
      end
    elseif M.is_var(y) then
      assert(match, ".match should be true for using match.variable")

      y.name = y.name or k
      local test = y.test
      local name = y.name

      if is_nil(test) then
        Vars[name] = x
      elseif is_table(test) then
        if not is_table(x) then
          if ass then
            error(prefix .. ": expected table, got " .. type(x))
          else
            return false
          end
        else
          Vars[name] = {}
          queue:add { x, test, vars = Vars[name], prefix = prefix  }
        end
      elseif is_function(test) then
        local ok, msg = test(x)
        if ok then
          Vars[name] = x
        elseif ass then
          if msg then
            error(prefix .. ": " .. msg)
          end
          error(prefix .. ": callable failed for " .. dump(x))
        else
          return false
        end
      else
        error "match.variable.test should be (function|table)?"
      end
    elseif is_table(y) then
      if not is_table(x) then
        if ass then
          error(prefix .. ": expected table, got " .. type(x))
        elseif absolute then
          return false
        else
          State[key] = false
        end
      elseif not absolute then
        State[k] = {}
        queue:add {
          x,
          y,
          prefix = prefix .. "." .. key,
          state = State--[[@as table]][k],
        }
      elseif match then
        queue:add { x, y, vars = Vars, prefix = prefix }
      else
        queue:add { x, y, prefix = prefix }
      end
    elseif (cond or match) and is_function(y) then
      local ok, msg = y(x)
      if ok then
        if not absolute then
          State[key] = true
        end
      elseif ass then
        if msg then
          error(prefix .. ": " .. msg)
        end
        error(prefix .. ": callable failed for " .. dump(obj_value))
      elseif absolute then
        return false
      else
        State[key] = false
      end
    elseif eq then
      if eq(x, y) then
        if not absolute then
          State[key] = true
        end
      elseif ass then
        error(prefix .. ": unequal elements: \n" .. dump(x) .. "\n" .. dump(y))
      elseif absolute then
        return false
      end
    elseif x ~= y then
      if ass then
        error(prefix .. ": unequal elements: \n" .. dump(x) .. "\n" .. dump(y))
      elseif absolute then
        return false
      else
        State[key] = false
      end
    elseif not absolute then
      State[key] = true
    end

    return true
  end

  local function resolve_key(i)
    key, optional = tostring(i):gsub("(^opt_|%?$)", "")
    key = tonumber(key) or key

    return key, optional > 0
  end

  while Obj and Spec do
    if same_size and size(Obj) ~= size(Spec) then
      return false
    end

    for i, validator in pairs(Spec) do
      local key = i
      local obj_value
      local optional

      if is_string(i) or is_number(i) then
        key, optional = resolve_key(i)
        obj_value = Obj[key]
      else
        obj_value = Obj[i]
      end

      if not cmp(obj_value, validator, i, optional, prefix) then
        return false
      end
    end

    local next_items = queue:pop()
    if next_items then
      Obj, Spec = next_items[1], next_items[2]
      prefix = next_items.prefix

      if match then
        Vars = next_items.vars or Vars
      end

      if not absolute then
        State = next_items.state or State
      end
    else
      Obj = nil
      Spec = nil
    end
  end

  if match then
    if size(vars) == 0 then
      return obj
    end
    return vars
  elseif cond and absolute then
    return obj
  else
    return state
  end
end

function M.ne.match(a, b, opts)
  opts = copy(opts or {})
  opts.match = true

  return M.ne.test(a, b, opts)
end

function M.ne.cond(a, b, opts)
  opts = copy(opts or {})
  opts.cond = true

  return M.ne.test(a, b, opts)
end

function M.ne:__call(a, b, opts)
  opts = copy(opts or {})
  opts.absolute = true

  return M.ne.test(a, b, opts)
end

function M.ne.compare(a, b, opts)
  opts = copy(opts or {})
  opts.absolute = false
  opts.match = false
  opts.cond = false

  return M.ne.test(a, b, opts)
end

function M.match(a, b, opts)
  opts = copy(opts or {})
  opts.match = true

  return M.test(a, b, opts)
end

function M.cond(a, b, opts)
  opts = copy(opts or {})
  opts.cond = true

  return M.test(a, b, opts)
end

function M.eq(a, b, opts)
  opts = copy(opts or {})
  opts.absolute = true

  return M.test(a, b, opts)
end

function M.compare(a, b, opts)
  opts = copy(opts or {})
  opts.absolute = false
  opts.match = false
  opts.cond = false

  return M.test(a, b, opts)
end

function M.unpack(a, b)
  opts = opts or {}
  opts.capture = true
  return M.test(a, b, opts)
end

local Eq = M.rules
local Ne = M.ne.rules

function Ne.strmatch(patterns)
  return function(obj)
    if not is_a.string(obj) then
      return false
    end

    local failure = 0
    local len = #patterns

    for i = 1, len do
      local pat = patterns[i]
      assertisa[union("string", "table")](pat)

      if is_table(pat) then
        local ok = string.match(obj, pat[1])
        if not (pat.optional or pat.opt) and ok then
          failure = failure + 1
        end
      elseif string.match(obj, pat) then
        failure = failure + 1
      end
    end

    if failure == len then
      return false
    end

    return true
  end
end

function Eq.strmatch(patterns)
  return function(obj)
    if not is_a.string(obj) then
      return false
    end

    local failure = 0
    local len = #patterns

    for i = 1, len do
      local pat = patterns[i]
      assertisa[union("string", "table")](pat)

      if is_table(pat) then
        local ok = string.match(obj, pat[1])
        if not (pat.optional or pat.opt) and not ok then
          failure = failure + 1
        end
      elseif not string.match(obj, pat) then
        failure = failure + 1
      end
    end

    if failure == len then
      return false
    end

    return true
  end
end

function Ne.literal(spec)
  return function(obj)
    return obj ~= spec
  end
end

function Ne.table(spec)
  return function(obj)
    return dict.ne(obj, spec, true)
  end
end

function Ne.list(spec)
  return function(obj)
    return list.ne(obj, spec, true)
  end
end

function Eq.literal(spec)
  return function(obj)
    return obj == spec
  end
end

function Eq.table(spec)
  return function(obj)
    return dict.eq(obj, spec, true)
  end
end

function Eq.list(spec)
  return function(obj)
    return list.eq(obj, spec, true)
  end
end

function Ne.has(ks)
  return function(obj)
    return size(dict.fetch(obj, ks)) == 0
  end
end

function Ne.pred_any(preds)
  return function(obj)
    return list.some(preds, function(f)
      return not f(obj)
    end)
  end
end

function Eq.has(ks)
  return function(obj)
    return size(dict.fetch(obj, ks)) > 0
  end
end

function Eq.pred_any(preds)
  return function(obj)
    return list.some(preds, function(f)
      return f(obj)
    end)
  end
end

function Ne.pred(preds)
  return function(obj)
    return list.all(preds, function(f)
      return not f(obj)
    end)
  end
end

function Eq.pred(preds)
  return function(obj)
    return list.all(preds, function(f)
      return f(obj)
    end)
  end
end

function Ne.is_a(spec)
  return not is_a[spec]
end

function Eq.is_a(spec)
  return is_a[spec]
end

function Eq.lt(spec)
  assertisa.number(spec)

  return function(x)
    if is_table(x) or is_string(x) then
      return size(x) > spec
    elseif not is_number(x) then
      error("expected number, got " .. tostring(x))
    end

    return x < spec
  end
end

function Eq.le(spec)
  assertisa.number(spec)

  return function(x)
    if is_table(x) or is_string(x) then
      return size(x) <= spec
    elseif not is_number(x) then
      error("expected number, got " .. tostring(x))
    end

    return x <= spec
  end
end

function Eq.ge(spec)
  assertisa.number(spec)

  return function(x)
    if is_table(x) or is_string(x) then
      return size(x) >= spec
    elseif not is_number(x) then
      error("expected number, got " .. tostring(x))
    end

    return x >= spec
  end
end

function Eq.eq(spec)
  assertisa.number(spec)

  return function(x)
    if is_table(x) or is_string(x) then
      return size(x) == spec
    elseif not is_number(x) then
      error("expected number, got " .. tostring(x))
    end

    return x == spec
  end
end

function Eq.ne(spec)
  assertisa.number(spec)

  return function(x)
    if is_table(x) or is_string(x) then
      return size(x) ~= spec
    elseif not is_number(x) then
      error("expected number, got " .. tostring(x))
    end

    return x ~= spec
  end
end

function Eq.gt(spec)
  assertisa.number(spec)

  return function(x)
    if is_table(x) or is_string(x) then
      return size(x) > spec
    elseif not is_number(x) then
      error("expected number, got " .. tostring(x))
    end

    return x > spec
  end
end

local V = M.var

local shape = {
  { 1, 2, 3 },
  { 1, { 2 }, 3 },
  { 3, { 3 }, { "a", "b", "c" } },
}

local spec = {
  { 1, 2, 3 },
  {1, {2}, 3},
  {3, {3}, {'a', 'b', 'c'}},
}

local unpack_spec = {
  { "a", "b", "c" },
  { "D", "E", "F" },
  { "G", { "?" }, V "+" },
}

pp(M.test(shape, spec, { assert = true }))
