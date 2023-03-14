class "Set"

function Set:_init(t)
  local tp = typeof(t)
  assert(tp == List or tp == "table" or tp == Set, "expected Set|List|table, got " .. tostring(t))

  if tp == Set then
    return t
  end

  for i = 1, #t do
    rawset(self, t[i], t[i])
  end

  return self
end

function Set:len()
  return #(keys(self))
end

function Set:iter()
  local ks = keys(self)
  local i = 1
  local n = self:len()
  return function()
    if i > n then
      return
    end
    i = i + 1
    return i - 1, rawget(self, ks[i - 1])
  end
end

function Set:tolist()
  local t = {}
  local i = 1
  for x, _ in pairs(self) do
    t[i] = x
    i = i + 1
  end

  return t
end

function Set:clone()
  return Set(deepcopy(self:tolist()))
end

function Set:intersection(...)
  local X = self
  local out = Set {}

  for _, Y in ipairs { ... } do
    assert(is_a.t(Y) or is_a.Set(Y), "Y should either be an array or a Set")
    Y = Set(Y)

    for x, _ in pairs(X) do
      if Y[x] then
        out:add(x)
      end
    end

    for y, _ in pairs(Y) do
      if X[y] then
        out:add(y)
      end
    end
  end

  return out
end

function Set:disjoint(y)
  return self:intersection(y):len() == 0
end

function Set:complement(...)
  local X = self
  local out = Set {}
  local Z = self:intersection(...)

  for x, _ in pairs(X) do
    if not Z[x] then
      out:add(x)
    end
  end

  return out
end

function Set:union(...)
  local X = self
  local out = Set {}

  for _, Y in ipairs { ... } do
    assert(is_a.t(Y) or is_a.Set(Y), "Y should either be an array or a Set")
    Y = Set(Y)

    for x, _ in pairs(X) do
      out:add(x)
    end

    for y, _ in pairs(Y) do
      out:add(y)
    end
  end

  return out
end

function Set:__sub(b)
  if not is_a(b, Set) and not is_a(b, "t") then
    local copy = self:clone()
    copy:remove(b)
    return copy
  end
  return self:difference(b)
end

function Set:__add(b)
  if not is_a(b, Set) and not is_a(b, "t") then
    return Set(self:add(b))
  end
  return self:union(b)
end

function Set:__pow(b)
  if not is_a(b, Set) and not is_a(b, "t") then
    return Set(self:add(b))
  end
  return self:intersection(b)
end

function Set:sort(f)
  return table.sort(self:tolist(), f)
end

function Set:values()
  return keys(self)
end

function Set:difference(...)
  local X = self
  local out = Set {}

  for _, Y in ipairs { ... } do
    -- For performance reasons :(
    assert(is_a.t(Y) or is_a.Set(Y), "Y should either be an array or a Set")

    Y = Set(Y)
    for x, _ in pairs(X) do
      if not Y[x] then
        out:add(x)
      end
    end
  end

  return out
end

function Set:__le(other)
  return self:is_subset(other)
end

function Set:__ge(other)
  return self:is_superset(other)
end

function Set:__lt(other)
  return self:is_subset(other)
end

function Set:__gt(other)
  return self:is_superset(other)
end

function Set:__mod(f)
  return self:map(f)
end

function Set:__div(f)
  return self:filter(f)
end

function Set:__mul(f)
  return self:each(f)
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
  assert(element ~= nil, "Element cannot be nil")

  local value = deepcopy(self[element])
  self[element] = nil

  return value
end

function Set:add(element)
  assert(element ~= nil, "Element cannot be nil")

  if not self[element] then
    self[element] = element
  end

  return self
end

function Set:contains(e)
  return self[e] ~= nil
end
