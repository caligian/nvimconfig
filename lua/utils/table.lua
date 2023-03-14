Map = require "pl.Map"
OrderedMap = require "pl.OrderedMap"
MultiMap = require "pl.MultiMap"
List = require "pl.List"

function len(t)
  if type(t) == 'string' then
    return #t
  elseif type(t) == 'table' then
    if t.len then
      return t:len()
    elseif t.length then
      return t:length()
    end
    return #t
  end
  return false
end

function append(t, ...)
  local idx = #t
  for i, value in ipairs { ... } do
    t[idx + i] = value
  end

  return t
end

function iappend(t, idx, ...)
  for _, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function unshift(t, ...)
  for idx, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function tolist(x, force)
  if is_a(x, Set) then
    return x:tolist()
  end

  if force or type(x) ~= "table" then
    return { x }
  end

  return x
end

function shift(t, times)
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

local function get_iterator(t, is_dict)
  assert(
    is_a.Map(t)
      or is_a.MultiMap(t)
      or is_a.OrderedMap(t)
      or is_a.List(t)
      or is_a.Set(t)
      or is_a.table(t),
    "t: Map|OrderedMap|MultiMap|List|Set|table expected, got " .. tostring(t)
  )

  if is_a.Map(t) or is_a.OrderedMap(t) or is_a.MultiMap(t) or is_a.List(t) or is_a.Set(t) then
    if is_a.List(t) then
      return function(list)
        local it = list:iter()
        local idx = 1
        local n = list:len()
        return function()
          if idx > n then
            return
          end
          idx = idx + 1
          return idx - 1, it()
        end
      end
    end
    return t.iter
  end

  if is_dict then
    return pairs
  else
    return ipairs
  end
end

local function iterate(t, is_dict, f, convert_to, ignore_false)
  local it = get_iterator(t, is_dict)
  local cls = convert_to or typeof(t)
  local out

  if is_a.t(cls) then
    out = cls {}
  else
    out = {}
  end

  for key, value in it(t) do
    local o = f(key, value)
    if o then
      if is_dict then
        out[key] = o
      else
        append(out, o)
      end
    elseif not ignore_false then
      if is_dict then
        out[key] = o
      else
        append(out, o)
      end
    end
  end

  return out
end

function index(t, item, test)
  assert(is_a.t(t) or is_a.List(t), "expected table|list, got " .. tostring(t))

  if test then
    assert(is_a.f(test), "expected callable, got " .. tostring(test))
  end

  for key, v in get_iterator(t, false)(t) do
    if test then
      if test(v, item) then
        return key
      end
    elseif item == v then
      return key
    end
  end
end

function teach(t, f)
  iterate(t, true, f)
end

function ieach(t, f)
  iterate(t, false, function(idx, x)
    f(idx, x)
  end)
end

function each(t, f)
  iterate(t, false, function(_, x)
    f(x)
  end)
end

function imap(t, f)
  return iterate(t, false, function(idx, x)
    return f(idx, x)
  end)
end

function map(t, f)
  return iterate(t, false, function(_, x)
    return f(x)
  end)
end

function tmap(t, f)
  return iterate(t, true, f)
end

function tgrep(t, f)
  return iterate(t, true, function(k, x)
    if f(k, x) then
      return x
    else
      return false
    end
  end, false, true)
end

function igrep(t, f)
  return iterate(t, false, function(idx, x)
    if f(idx, x) then
      return x
    else
      return false
    end
  end, false, true)
end

function grep(t, f)
  return iterate(t, false, function(_, x)
    if f(x) then
      return x
    else
      return false
    end
  end, false, true)
end

function tfilter(t, f)
  return iterate(t, true, function(k, x)
    if f(k, x) then
      return x
    else
      return false
    end
  end, false, true)
end

function ifilter(t, f)
  return iterate(t, false, function(idx, x)
    if f(idx, x) then
      return x
    else
      return false
    end
  end)
end

function filter(t, f)
  return iterate(t, false, function(_, x)
    if f(x) then
      return x
    else
      return false
    end
  end, false, true)
end

function items(t)
  assert(not is_a.List(t) and not is_a.Set(t), "expected t/Map/Map-like, got " .. tostring(t))

  local it = get_iterator(t)
  local out = List {}
  for key, val in it(t) do
    out[#out + 1] = { key, val }
  end

  return out
end

function setro(t)
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

function mtget(t, k)
  assert(type(t) == "table", "expected table, got " .. tostring(t))
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t)
  if not mt then
    return nil
  end

  return rawget(mt, k)
end

function mtset(t, k, v)
  assert(type(t) == "table", "expected table, got " .. tostring(t))
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t)
  if not mt then
    setmetatable(t, { [k] = v })
    mt = getmetatable(t)
  else
    rawset(mt, k, v)
  end

  return mt[k]
end

function isblank(s)
  assert(
    is_a.s(s) or is_a.t(s) or is_a.Set(s) or is_a.List(s),
    "expected string|table|Set|List, got " .. tostring(s)
  )

  if is_a.Set(s) or is_a.List(s) then
    return s:len() == 0
  end

  if type(s) == "string" then
    return #s == 0
  elseif type(s) == "table" then
    local i = 0
    for _, _ in pairs(s) do
      i = i + 1
    end
    return i == 0
  end
end

function extend(tbl, ...)
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

function compare(a, b, callback)
  local depth, compared, state = 1, {}, nil
  state = compared

  local function _compare(a, b)
    local ks_a = Set(keys(a))
    local ks_b = Set(keys(b))
    local common = ks_a:intersection(ks_b)
    local missing = ks_a - ks_b

    each(missing, function(key)
      state[key] = false
    end)

    each(common, function(key)
      local x, y = a[key], b[key]
      if is_a.t(x) and is_a.t(y) then
        depth = depth + 1
        state[key] = {}
        state = state[key]
        _compare(x, y)
      elseif callback then
        state[key] = callback(x, y)
      else
        state[key] = typeof(x) == typeof(y) and x == y
        if depth > 1 then
          pp(compared)
        end
      end
    end)
  end

  _compare(a, b, _state)
  return _state
end

function butlast(t)
  local new = {}

  for i = 1, #t - 1 do
    new[i] = t[i]
  end

  return new
end

function last(t, n)
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

function rest(t)
  local new = {}
  local len = #t
  local idx = 1

  for i = 2, len do
    new[idx] = t[i]
    idx = idx + 1
  end

  return new
end

function first(t, n)
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

function update(tbl, keys, value)
  keys = tolist(keys)
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

function get(tbl, ks, create_path)
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

function slice(t, from, till)
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

function contains(tbl, ...)
  return (get(tbl, { ... }))
end

function makepath(t, ...)
  return get(t, { ... }, true)
end

function lmerge(...)
  local function _merge(t1, t2)
    local later = {}

    teach(t2, function(k, v)
      local a, b = t1[k], t2[k]

      if a == nil then
        t1[k] = v
      elseif is_a.t(a) and is_a.t(b) then
        append(later, { a, b })
      end
    end)

    each(later, function(next)
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

function merge(...)
  local function _merge(t1, t2)
    local later = {}

    teach(t2, function(k, v)
      local a, b = t1[k], t2[k]

      if a == nil then
        t1[k] = v
      elseif is_a.t(a) and is_a.t(b) then
        append(later, { a, b })
      else
        t1[k] = v
      end
    end)

    each(later, function(next)
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

function items(t)
  if is_a.Map(t) or is_a.OrderedMap(t) or is_a.MultiMap(t) then
    return t:items()
  end

  local it = {}
  local i = 1
  for key, value in pairs(t) do
    it[i] = { key, value }
    i = i + 1
  end

  return it
end

function range(from, till, step)
  local index = from
  step = step or 1

  return function()
    index = index + step
    if index <= till then
      return index
    end
  end
end

MultiMap.merge = merge
MultiMap.lmerge = lmerge
MultiMap.makepath = makepath
MultiMap.filter = tfilter
MultiMap.each = teach
MultiMap.map = tmap
MultiMap.grep = tgrep
MultiMap.items = items
MultiMap.update = update
MultiMap.get = get
MultiMap.contains = contains

OrderedMap.merge = merge
OrderedMap.lmerge = lmerge
OrderedMap.filter = tfilter
OrderedMap.each = teach
OrderedMap.map = tmap
OrderedMap.grep = tgrep
OrderedMap.items = items
OrderedMap.update = update
OrderedMap.get = get
OrderedMap.contains = contains
OrderedMap.makepath = makepath

Map.merge = merge
Map.lmerge = lmerge
Map.makepath = makepath
Map.filter = tfilter
Map.each = teach
Map.map = tmap
Map.grep = tgrep
Map.items = items
Map.update = update
Map.get = get
Map.contains = contains

List.makepath = makepath
List.get = get
List.each = each
List.map = map
List.grep = grep
List.filter = filter
List.ifilter = ifilter
List.ieach = ieach
List.imap = ieach
List.igrep = igrep
List.index = index
List.extend = extend
List.butlast = butlast
List.last = last
List.first = first
List.head = first
List.rest = rest
List.tail = rest
List.update = update
List.contains = contains
List.lmerge = lmerge
List.merge = merge


Set.each = each
Set.map = map
Set.grep = grep
Set.filter = filter
Set.ifilter = ifilter
Set.ieach = ieach
Set.imap = ieach
Set.igrep = igrep
