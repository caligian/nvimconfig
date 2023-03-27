table.teach = table.foreach
table.ieach = table.foreachi
table.keys = vim.tbl_keys
table.values = vim.tbl_values
table.copy = vim.deepcopy
table.isempty = vim.tbl_is_empty
table.flatten = vim.tbl_flatten
Map = require "pl.Map"
OrderedMap = require "pl.OrderedMap"
MultiMap = require "pl.MultiMap"
List = require "pl.List"

function table.append(t, ...)
  local idx = #t
  for i, value in ipairs { ... } do
    t[idx + i] = value
  end

  return t
end

function table.iappend(t, idx, ...)
  for _, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function table.unshift(t, ...)
  for idx, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function table.tolist(x, force)
  if force or type(x) ~= "table" then
    return { x }
  end

  return x
end

function table.todict(x)
  if type(x) ~= "table" then
    return { [x] = x }
  end

  local out = {}
  for _, v in pairs(x) do
    out[v] = v
  end

  return out
end

function table.shift(t, times)
  local l = #t
  times = times or 1
  for i = 1, times do
    if i > l then
      return t
    end
    table.remove(t, 1)
  end

  return t
end

function table.index(t, item, test)
  for key, v in pairs(t) do
    if test then
      if test(v, item) then
        return key
      end
    elseif item == v then
      return key
    end
  end
end

function table.each(t, f)
  for _, v in ipairs(t) do
    f(v)
  end
end

function table.igrep(t, f)
  local out = {}
  local i = 1

  for k, v in ipairs(t) do
    local o = f(k, v)
    if o then
      out[i] = v
      i = i + 1
    end
  end

  return out
end

function table.tgrep(t, f)
  local out = {}

  for k, v in pairs(t) do
    local o = f(k, v)
    if o then
      out[k] = v
    end
  end

  return out
end

function table.grep(t, f)
  local out = {}
  local i = 1
  for _, v in ipairs(t) do
    local o = f(v)
    if o then
      out[i] = v
      i = i + 1
    end
  end

  return out
end

function table.filter(t, f)
  local out = {}
  for _, v in ipairs(t) do
    local o = f(v)
    if o then
      out[idx] = v
    else
      out[idx] = false
    end
  end

  return out
end

function table.tfilter(t, f)
  local out = {}
  for idx, v in pairs(t) do
    local o = f(idx, v)
    if o then
      out[idx] = v
    else
      out[idx] = false
    end
  end

  return out
end

function table.ifilter(t, f)
  local out = {}
  for idx, v in ipairs(t) do
    local o = f(idx, v)
    if o then
      out[idx] = v
    else
      out[idx] = false
    end
  end

  return out
end

function table.tmap(t, f)
  local out = {}
  for k, v in pairs(t) do
    v = f(k, v)
    assert(v ~= nil, "non-nil expected, got " .. v)
    out[idx] = v
  end

  return out
end

function table.map(t, f)
  local out = {}
  for idx, v in ipairs(t) do
    v = f(v)
    assert(v ~= nil, "non-nil expected, got " .. v)
    out[idx] = v
  end

  return out
end

function table.imap(t, f)
  local out = {}
  for idx, v in ipairs(t) do
    v = f(idx, v)
    assert(v ~= nil, "non-nil expected, got " .. v)
    out[idx] = v
  end

  return out
end

function table.items(t)
  local out = {}
  for key, val in pairs(t) do
    out[#out + 1] = { key, val }
  end

  return out
end

function table.setro(t)
  assert(type(t) == "table", tostring(t) .. " is not a table")

  local function __newindex()
    error "Attempting to edit a readonly table"
  end

  local mt = getmetatable(t)
  if not mt then
    setmetatable(t, { __newindex = __newindex })
    mt = getmetatable(t)
  else
    mt.__newindex = __newindex
  end

  return t
end

function table.mtget(t, k)
  assert(type(t) == "table", "expected table, got " .. tostring(t))
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t)
  if not mt then
    return nil
  end

  local out = {}
  if type(k) == "table" then
    for _, v in ipairs(k) do
      out[v] = rawget(mt, v)
    end

    return out
  end

  return rawget(mt, k)
end

function table.mtset(t, k, v)
  assert(type(t) == "table", "expected table, got " .. tostring(t))
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t) or {}
  if type(k) == "table" then
    for idx, v in pairs(k) do
      rawset(mt, idx, v)
    end
    return setmetatable(t, mt)
  end

  rawset(mt, k, v)
  setmetatable(t, mt)

  return mt
end

function table.len(t)
  local i = 0
  for _, _ in pairs(t) do
    i = i + 1
  end

  return i
end

function table.isblank(s)
  if type(s) == "string" then
    return #s == 0
  elseif type(s) == "table" then
    return table.len(s) == 0
  end
end

function table.extend(tbl, ...)
  local l = #tbl
  for i, t in ipairs { ... } do
    if type(t) == "table" then
      for j, value in ipairs(t) do
        tbl[l + j] = value
      end
    else
      tbl[l + i] = t
    end
  end

  return tbl
end

function table.compare(a, b, callback)
  local depth, compared, state = 1, {}, nil
  state = compared

  local function _compare(a, b)
    local ks_a = Set(table.keys(a))
    local ks_b = Set(table.keys(b))
    local common = ks_a:intersection(ks_b)
    local missing = ks_a - ks_b

    missing:each(function(key)
      compared[key] = false
    end)

    common:each(function(key)
      local x, y = a[key], b[key]
      if is_a.t(x) and is_a.t(y) then
        depth = depth + 1
        compared[key] = {}
        compared = state[key]
        _compare(x, y)
      elseif callback then
        compared[key] = callback(x, y)
      else
        compared[key] = x == y
      end
    end)
  end

  _compare(a, b)
  return state
end

function table.butlast(t)
  local new = {}

  for i = 1, #t - 1 do
    new[i] = t[i]
  end

  return new
end

function table.last(t, n)
  if n then
    local len = #t
    local new = {}
    local idx = 1
    for i = len - n + 1, len do
      new[idx] = t[i]
      idx = idx + 1
    end

    return new
  else
    return t[#t]
  end
end

function table.rest(t)
  local new = {}
  local len = #t
  local idx = 1

  for i = 2, len do
    new[idx] = t[i]
    idx = idx + 1
  end

  return new
end

function table.first(t, n)
  if n then
    local new = {}
    for i = 1, n do
      new[i] = t[i]
    end

    return new
  else
    return t[1]
  end
end

function table.update(tbl, keys, value)
  keys = table.tolist(keys)
  local len_ks = #keys
  local t = tbl

  for idx, k in ipairs(keys) do
    local v = t[k]

    if idx == len_ks then
      t[k] = value
      return value, t, tbl
    elseif type(v) == "table" then
      t = t[k]
    elseif v == nil then
      t[k] = {}
      t = t[k]
    else
      return
    end
  end
end

function table.get(tbl, ks, create_path)
  if type(ks) ~= "table" then
    ks = { ks }
  end

  local len_ks = #ks
  local t = tbl
  local v = nil
  for index, k in ipairs(ks) do
    v = t[k]

    if v == nil then
      if create_path then
        t[k] = {}
        t = t[k]
      else
        return
      end
    elseif type(v) == "table" then
      t = t[k]
    elseif len_ks ~= index then
      return
    end
  end

  return v, t, tbl
end

function table.slice(t, from, till)
  local l = #t
  if from < 0 then
    from = l + from
  end
  if till < 0 then
    till = l + till
  end

  if from > till and from > 0 then
    return {}
  end

  local out = {}
  local idx = 1
  for i = from, till do
    out[idx] = t[i]
    idx = idx + 1
  end

  return out
end

function table.contains(tbl, ...)
  return (table.get(tbl, { ... }))
end

function table.makepath(t, ...)
  return table.get(t, { ... }, true)
end

function table.lmerge(...)
  local function _merge(t1, t2)
    local later = {}

    table.teach(t2, function(k, v)
      local a, b = t1[k], t2[k]

      if a == nil then
        t1[k] = v
      elseif is_a.t(a) and is_a.t(b) then
        table.append(later, { a, b })
      end
    end)

    table.each(later, function(next)
      _merge(unpack(next))
    end)
  end

  local args = { ... }
  local l = #args
  local start = args[1]

  for i = 2, l do
    _merge(start, args[i])
  end

  return start
end

function table.merge(...)
  local function _merge(t1, t2)
    local later = {}

    table.teach(t2, function(k, v)
      local a, b = t1[k], t2[k]

      if a == nil then
        t1[k] = v
      elseif is_a.t(a) and is_a.t(b) then
        table.append(later, { a, b })
      else
        t1[k] = v
      end
    end)

    table.each(later, function(next)
      _merge(unpack(next))
    end)
  end

  local args = { ... }
  local l = #args
  local start = args[1]

  for i = 2, l do
    _merge(start, args[i])
  end

  return start
end

function table.range(from, till, step)
  step = step or 1
  local out = {}
  local idx = 1

  for i = from, till, step do
    out[idx] = i
    idx = idx + 1
  end

  return out
end

string.isblank = table.isblank
