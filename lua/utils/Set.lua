require "utils.Dict"
require "utils.Array"

class "Set"

function Set:init(t)
  assert(type(t) == "table", "table expected, got " .. type(t))

  if is_class(t) then
    local name = t.class:get_name()
    if name ~= "Set" then
      error("Set|table expected, got " .. name)
      return self
    else
      t = t.value
    end
  end

  self.value = {}
  for _, value in pairs(t) do
    self.value[value] = value
  end

  return self
end

function Set:has(x)
  return self.value[x]
end

function Set:add(x)
  self.value[x] = x
end

function Set:items(cmp)
  local X = table.values(self.value)

  if cmp then
    if cmp == true then
      table.sort(X)
    else
      table.sort(X, cmp)
    end
  end

  return X
end

function Set:each(f)
  Array.each(self:items(), f)
end

function Set:map(f)
  return Array.map(self:items(), f)
end

function Set:grep(f)
  return Array.grep(self:items(), f)
end

function Set:filter(f)
  return Array.filter(self:items(), f)
end

function Set:len()
  return #(table.keys(self.value))
end

function Set:intersection(...)
  local out = Set {}

  for _, Y in ipairs { ... } do
    Y = Set(Y)

    self:each(function(x)
      if Y:has(x) then
        out:add(x)
      end
    end)

    Y:each(function(y)
      if self:has(y) then
        out:add(y)
      end
    end)
  end

  return out
end

function Set:disjoint(y)
  return self:intersection(y):len() == 0
end

function Set:complement(...)
  local out = Set.new {}
  local Z = self:intersection(...)

  self:each(function(x)
    if not Z:has(x) then
      out:add(x)
    end
  end)

  return out
end

function Set:union(...)
  local out = Set.new {}

  for _, Y in ipairs { ... } do
    Y = Set.new(Y)

    self:each(function(x)
      out:add(x)
    end)

    Y:each(function(y)
      out:add(y)
    end)
  end

  return out
end

function Set:difference(...)
  local out = Set.new {}

  for _, Y in ipairs { ... } do
    Y = Set.new(Y)
    self:each(function(x)
      if not Y:has(x) then
        out:add(x)
      end
    end)
  end

  return out
end

Set.__sub = Set.difference
Set.__add = Set.union
Set.__pow = Set.intersection

function Set:__le(other)
  return self:len() <= other:len()
end

function Set:__ge(other)
  return self:len() >= other:len()
end

function Set:__lt(other)
  return self:len() < other:len()
end

function Set:__gt(other)
  return self:len() > other:len()
end

function Set:is_subset(other)
  other = Set(other)
  return self:difference(other):len() == 0
end

function Set:is_superset(other)
  other = Set(other)
  return other:difference(self):len() == 0
end

function Set:remove(element)
  local has = self.value[element]
  if has then
    self.value[element] = nil
    return vim.deepcopy(has)
  end
end
