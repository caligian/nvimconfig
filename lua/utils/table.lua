array = {}
dict = {}
dict.keys = vim.tbl_keys
dict.values = vim.tbl_values
dict.copy = vim.deepcopy
dict.isblank = vim.tbl_is_empty
array.flatten = vim.tbl_flatten
array.copy = dict.copy
array.join = table.concat
array.concat = array.join
array.remove = table.remove

function array.sort(x, cmp)
  table.sort(x, cmp)
  return x
end

function array.isblank(x)
  return #x == 0
end

function array.append(t, ...)
  local idx = #t
  for i, value in ipairs { ... } do
    t[idx + i] = value
  end

  return t
end

function array.iappend(t, idx, ...)
  for _, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function array.unshift(t, ...)
  for idx, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function array.tolist(x, force)
  if force or type(x) ~= "table" then
    return { x }
  end

  return x
end

array.toarray = array.tolist

function array.todict(x)
  if type(x) ~= "table" then
    return { [x] = x }
  end

  local out = {}
  for _, v in pairs(x) do
    out[v] = v
  end

  return out
end

function array.shift(t, times)
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

function array.index(t, item, test)
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

function array.ieach(t, f)
  for _, v in ipairs(t) do
    f(_, v)
  end
end

function array.each(t, f)
  for _, v in ipairs(t) do
    f(v)
  end
end

function array.igrep(t, f)
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

function dict.grep(t, f)
  local out = {}

  for k, v in pairs(t) do
    local o = f(k, v)
    if o then
      out[k] = v
    end
  end

  return out
end

function array.grep(t, f)
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

function array.filter(t, f)
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

function dict.filter(t, f)
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

function array.ifilter(t, f)
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

function dict.map(t, f)
  local out = {}
  for k, v in pairs(t) do
    local o = f(k, v)
    assert(o ~= nil, "non-nil expected")
    out[k] = o
  end

  return out
end

function array.map(t, f)
  local out = {}
  for idx, v in ipairs(t) do
    v = f(v)
    assert(v ~= nil, "non-nil expected")
    out[idx] = v
  end

  return out
end

function array.imap(t, f)
  local out = {}
  for idx, v in ipairs(t) do
    v = f(idx, v)
    assert(v ~= nil, "non-nil expected, got " .. tostring(v))
    out[idx] = v
  end

  return out
end

function dict.items(t)
  local out = {}
  local i = 1
  for key, val in pairs(t) do
    out[i] = { key, val }
    i = i + 1
  end

  return out
end

function dict.setro(t)
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

function dict.len(t)
  local i = 0
  for _, _ in pairs(t) do
    i = i + 1
  end

  return i
end

function array.len(x)
  return #x == 0
end

function dict.isblank(s)
  if type(s) == "string" then
    return #s == 0
  elseif type(s) == "table" then
    return dict.len(s) == 0
  end
end

array.isblank = dict.isblank

function array.extend(tbl, ...)
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

function array.compare(a, b, callback, no_state)
  if not is_table(a) or not is_table(b) then
    return false
  end
  local depth, compared = 1, {}
  local state = compared
  local all_equal

  local function _compare(x, y)
    local later = {}
    for key, value in pairs(x) do
      local y_value = y[key]
      if not y_value then
        state[key] = false
      elseif is_table(y_value) then
        if not is_table(value) then
          state[key] = false
        elseif not is_class(value) and not is_class(y_value) then
          state[key] = {}
          state = state[key]
          later[#later + 1] = { key, value, y_value }
        elseif callback then
          state[key] = callback(value, y_value)
        else
          state[key] = value == y_value
        end
      elseif callback then
        state[key] = callback(value, y_value)
      else
        state[key] = value == y_value
      end

      for _, value in ipairs(later) do
        local key, x_value, y_value = unpack(value)
        _compare(x_value, y_value, state)
      end

      all_equal = state[key]
      if no_state and not all_equal then
        return false
      end
    end
  end

  _compare(a, b)

  if no_state then
    return all_equal
  end
  return compared, all_equal
end

function array.last(t)
  local new = {}

  for i = 1, #t - 1 do
    new[i] = t[i]
  end

  return new
end

function array.butlast(t, n)
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

function array.rest(t)
  local new = {}
  local len = #t
  local idx = 1

  for i = 2, len do
    new[idx] = t[i]
    idx = idx + 1
  end

  return new
end

function array.first(t, n)
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

function dict.update(tbl, keys, value)
  keys = array.tolist(keys)
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

array.update = dict.update

function dict.get(tbl, ks, create_path)
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

array.get = dict.get

function array.slice(t, from, till)
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

function dict.contains(tbl, ...)
  return (dict.get(tbl, { ... }))
end

array.contains = dict.contains

function dict.makepath(t, ...)
  return dict.get(t, { ... }, true)
end

array.makepath = dict.makepath

function dict.each(t, f)
  for key, value in pairs(t) do
    f(key, value)
  end
end

function dict.lmerge(...)
  local function _merge(t1, t2)
    local later = {}

    dict.each(t2, function(k, v)
      local a, b = t1[k], t2[k]

      if a == nil then
        t1[k] = v
      elseif is_a.t(a) and is_a.t(b) then
        array.append(later, { a, b })
      end
    end)

    array.each(later, function(next)
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

function dict.merge(...)
  local function _merge(t1, t2)
    local later = {}

    dict.each(t2, function(k, v)
      local a, b = t1[k], t2[k]

      if a == nil then
        t1[k] = v
      elseif is_a.t(a) and is_a.t(b) then
        array.append(later, { a, b })
      else
        t1[k] = v
      end
    end)

    array.each(later, function(next)
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

function array.range(from, till, step)
  step = step or 1
  local out = {}
  local idx = 1

  for i = from, till, step do
    out[idx] = i
    idx = idx + 1
  end

  return out
end

function array.zip2(a, b)
  assert(type(a) == "table", "expected table, got " .. tostring(a))
  assert(type(b) == "table", "expected table, got " .. tostring(a))

  local len_a, len_b = #a, #b
  local n = len_a > len_b and len_b or len_a < len_b and len_a or len_a
  local out = {}
  for i = 1, n do
    out[i] = { a[i], b[i] }
  end

  return out
end

function array.zip(...)
  local args = { ... }
  local len_args = #args
  local n = {}

  for i = 1, len_args do
    if type(args[i]) ~= "table" then
      error(i .. ": table expected, got " .. tostring(args[i]))
    end
    n[i] = #args[i]
  end

  table.sort(n)
  n = n[1]
  local idx = 1
  local out = {}

  for i = 1, n do
    out[i] = {}
    for j = 1, len_args do
      out[i][j] = args[j][i]
    end
  end

  return out
end

function dict.delete(x, ks)
  local t = x
  local found
  local i = 1
  ks = array.tolist(ks)
  local n = #ks

  while not found do
    local k = ks[i]
    local v = t[k]
    if not v then
      return
    end

    if i == n then
      found = k
    elseif is_seq(v) then
      t = v
    else
      found = k
    end

    i = i + 1
  end

  if found then
    t[found] = nil
  end

  return found
end

array.delete = dict.delete
