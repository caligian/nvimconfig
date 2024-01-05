require "lua-utils.utils"
require "lua-utils.table"
require "lua-utils.compare"

--- @alias Iterable table|function|str

--- @class iterable
--- @field state function|string|table|list
--- @field f function
--- @field next any
--- @field current any
--- @field remaining table|boolean
--- @field islist boolean
--- @field isdict boolean
--- @field isstring boolean
--- @field isfunction boolean
--- @field keys any[]|boolean
--- @field at any
--- @overload fun(a: table|function|string|list):iterable
iter = class "iterable"

--- @param self Iterable
--- @return boolean
function iter:is_iter()
  return typeof(self) == "iterable"
end

--- @param state Iterable
--- @return iterable
function iter:init(state)
  if iter.is_iter(state) then
    return state --[[@as iterable]]
  end

  params {
    state = {
      union("function", "table", "string"),
      state,
    },
  }

  self.f = yieldfn
  self.state = state
  self.islist = listlike(state --[[@as table]])
  self.isdict = not self.islist and is_table(state)
  self.isstring = is_string(state)
  self.isfunction = is_function(state)
  self.keys = self.isdict and keys(self.state --[[@as table]]) or false
  self.at = 1

  if self.isstring then
    ---@diagnostic disable-next-line
    self.state = string.charlist(self.state)
  elseif self.isdict then
    self.remaining = #self.keys --[[@as table]]
  elseif not self.isfunction then
    self.remaining = #self.state --[[@as table]]
  end

  return self
end

--- @param g? fun(key?, value): any
--- @return any key `key` is `value` when self.isdict
--- @return any value nil if not self.isdict
function iter:yield(g)
  if self.isfunction then
    local ok = self.state()
    if ok == nil then
      return
    elseif self.f then
      ok = self.f(ok)
      if ok == nil then
        return
      elseif g then
        ok = g(ok)
        if ok == nil then
          return
        end
        return ok
      end
    elseif g then
      return g(ok)
    else
      return ok
    end
  elseif self.remaining == 0 then
    return
  end

  local at = self.isdict and self.keys[self.at] or self.at
  self.remaining = self.remaining and self.remaining - 1
  local value = self.state[at]

  if value == nil then
    return
  end

  self.current = value
  self.at = self.at + 1
  local ok = value

  if self.f then
    ok = self.isdict and self.f(at, value) or self.f(value)
  end

  if g then
    ok = self.isdict and g(at, value) or g(value)
  end

  if ok == nil then
    return
  elseif self.isdict then
    return at, ok
  else
    return ok
  end
end

--- Return an iterator to use in `for` loops
--- @return function
function iter:iter()
  return function()
    return self:yield()
  end
end

--- Take N elements
--- @param n? number -1 for all elements
--- @return table
function iter:take(n)
  n = n or 1

  if n < 0 then
    n = self.remaining --[[@as num]]
  elseif self.remaining and n > self.remaining then
    n = self.remaining --[[@as num]]
  end

  local out = {}
  for _ = 1, n do
    local ok = { self:yield() }
    if #ok == 2 then
      out[ok[1]] = ok[2]
    elseif #ok == 1 then
      out[#out + 1] = ok[1]
    else
      return out
    end
  end

  return out
end

--- Reset iterable
--- @return iterable
function iter:reset()
  return iter(iter.state)
end

--- Apply a function
--- @param f function
--- @param n? num
--- @return table|list
function iter:map(f, n)
  if self.isdict then
    return dict.map(self:take(n or -1), f)
  else
    return list.map(self:take(n or -1), f)
  end
end

--- Filter using a function
--- @param f function
--- @param n? num
--- @return table|list
function iter:filter(f, n)
  if self.isdict then
    return dict.filter(self:take(n or -1), f)
  end

  return list.map(self:take(n or -1), f)
end

--- @return (table|list)?
function iter:is_table()
  if self.isdict or self.islist or self.isstring then
    return self.state --[[@as table]]
  else
    local out
    local ok = self.state()

    if ok == nil then
      return
    end

    out = { ok }
    while true do
      ok = { self.state() }
      local n = #ok

      if n > 1 then
        out[ok[1]] = ok[2]
      elseif n == 1 then
        out[#out + 1] = ok[1]
      else
        break
      end
    end

    return out
  end
end
