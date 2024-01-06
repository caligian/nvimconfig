require "lua-utils.utils"

list = list or module()
dict = dict or module()
dict.keys = keys
dict.values = values

--- TODO:
--- replace overloads for functions

--- @alias dict_mapper (fun(key, value): any)
--- @alias list_mapper (fun(elem): any)

--- Filter dict
--- @param x table
--- @param f dict_mapper
--- @param mapper? dict_mapper
--- @return table result table of filtered kv pairs
function dict.filter(x, f, mapper)
  local out = {}

  for i, v in pairs(x) do
    if f(i, v) then
      if mapper then
        out[i] = mapper(v)
      else
        out[i] = v
      end
    end
  end

  return out
end

--- Filter dict if f() fails
--- @param x table
--- @param f dict_mapper
--- @param mapper? dict_mapper
--- @return table
function dict.filterunless(x, f, mapper)
  local out = {}

  for i, v in pairs(x) do
    if not f(i, v) then
      if mapper then
        out[i] = mapper(v)
      else
        out[i] = v
      end
    end
  end

  return out
end

--- Filter list
--- @param x list
--- @param f list_mapper
--- @param mapper? list_mapper
--- @return list
function list.filter(x, f, mapper)
  local out = {}

  for i = 1, #x do
    if f(x[i]) then
      if mapper then
        out[#out + 1] = mapper(x[i])
      else
        out[#out + 1] = x[i]
      end
    end
  end

  return out
end

--- Filter list if f() fails
--- @param x list
--- @param f list_mapper
--- @param mapper? list_mapper
--- @return list
function list.filterunless(x, f, mapper)
  local out = {}

  for i = 1, #x do
    if not f(x[i]) then
      if mapper then
        out[#out + 1] = mapper(x[i])
      else
        out[#out + 1] = x[i]
      end
    end
  end

  return out
end

--- Map table with a function
--- @param x table
--- @param f dict_mapper
--- @param inplace? bool
--- @return table
function dict.map(x, f, inplace)
  local res
  if inplace then
    res = x
  else
    res = {}
  end

  for i, v in pairs(x) do
    v = f(i, v)
    assert(v ~= nil, "mapper cannot return non-nil: " .. tostring(x[i]))

    res[i] = v
  end

  return res
end

--- Map list with index
--- @param x list
--- @param f (fun(index: number, elem: any): any)
--- @param inplace? boolean
--- @return list
function list.mapi(x, f, inplace)
  local res
  if inplace then
    res = x
  else
    res = {}
  end

  for i = 1, #x do
    local v = f(i, x[i])
    assert(v ~= nil, "mapper cannot return non-nil: " .. tostring(x[i]))

    res[i] = v
  end

  return res
end

--- Map list
--- @param x list
--- @param f list_mapper
--- @param inplace? boolean
--- @return list
function list.map(x, f, inplace)
  local res
  if inplace then
    res = x
  else
    res = {}
  end

  for i = 1, #x do
    local v = f(x[i])
    assert(v ~= nil, "mapper cannot return non-nil: " .. tostring(x[i]))

    res[i] = v
  end

  return res
end

--- @class get.opts
--- @field level boolean return matching level info
--- @field create boolean create a table if all but last keys exist
--- @field force boolean create tables for all nonexistent keys and update/put value (if present)
--- @field update fun(x:any): any update existing value
--- @field default fun(): any return default() when key does not exist
--- @field put any put this value directly
--- @field rawget boolean use rawget for fetching
--- @field rawset boolean use rawset for setting

--- Fetch keys from a table
--- > local ks = {'a', 'b'}
--- > local t = {}
--- > local value, info = dict.get(t, ks, {force=true, default: function() return 1 end, level=true})
--- > -- value = {}
--- > -- info = {level={}, key='b', index=2}
--- > -- t = {a = {b = 1}}
--- @param x table
--- @param ks list
--- @param opts? get.opts
--- @return any found returns nil on failure
--- @return { level:table, index:number, key:any }|nil info returns only if `level` is true
function dict.get(x, ks, opts)
  assertisa.table(x)
  assertisa.table(ks)
  
  if opts then
    assertisa.table(opts)
  end

  opts = opts or {}
  local level = opts.level
  local create = opts.create
  local force = opts.force
  local update = opts.update
  local use_rawget = opts.rawget
  local use_rawset = opts.rawset
  local default = opts.default
  local put = opts.put
  local unset = opts.unset
  local v
  local k
  local res = {}
  local len = #ks
  local last_key = ks[len]

  if unset then
    assert(not force, "cannot use `unset` with `force`")
  end

  for i = 1, len - 1 do
    y = x
    k = ks[i]
    v = use_rawget and rawget(x, k) or x[k]
    res.level = y
    res.key = k
    res.index = i

    if is_table(v) then
      x = v
    elseif force then
      x[k] = {}
    elseif v == nil and create then
      x[k] = {}
    elseif level then
      if default then
        return default(), res
      end
      return nil, res
    else
      if default then
        return default()
      end
      return nil
    end
  end

  k = last_key
  res.index = len
  res.key = k
  res.level = x
  local found = use_rawget and rawget(x, k) or x[k]

  if found == nil and not force then
    if level then
      if default then
        return default(), res
      end
      return nil, res
    end

    if default then
      return default()
    end
    return nil
  end

  local ret = use_rawget and rawget(x, k) or x[k]
  if unset then
    if use_rawset then
      rawset(x, k, nil)
    else
      x[k] = nil
    end
  elseif put ~= nil then
    if use_rawset then
      rawset(x, k, put)
    else
      x[k] = put
    end
  elseif update then
    if use_rawset then
      rawset(x, k, update(found))
    else
      x[k] = update(found)
    end
  end

  if level then
    return ret, res
  end

  return ret
end

--- Set a value directly
--- @param x table
--- @param ks list
--- @param value any
--- @param level? bool
--- @see dict.get
--- @return any, table?
function dict.set(x, ks, value, level)
  local opts = {
    level = level,
    force = true,
    put = value,
    rawset = true,
  }
  return dict.get(x, ks, opts)
end

--- Update a value with a function
--- @param x table
--- @param ks list
--- @param fn fun(x: any): any
--- @param level boolean
--- @see dict.get
--- @return any, table?
function dict.update(x, ks, fn, level)
  local opts = { level = level, update = fn }
  return dict.get(x, ks, opts)
end

--- Extend list with other lists
--- @param x list
--- @param args list
--- @return list
function list.extend(x, args)
  for i = 1, #args do
    if is_table(args[i]) then
      for j = 1, #args[i] do
        x[#x + 1] = args[i][j]
      end
    else
      error("cannot extend table with a non-table: " .. inspect(args[i]))
    end
  end

  return x
end

--- Append elements to a list
--- @param x list
--- @param args any
--- @return list
function list.append(x, args)
  for i = 1, #args do
			x[#x + 1] = args[i]
  end

  return x
end

--- Insert element at position
--- @param x list
--- @param pos number
--- @param args any items to insert
--- @return list
function list.insert(x, pos, args)
  for i = #args, 1, -1 do
    table.insert(x, pos, args[i])
  end

  return x
end

--- Append items at the beginning
--- @param x list
--- @param args any
--- @return list
function list.lappend(x, args)
  return list.insert(x, 1, args)
end

--- Extend list at the beginning with other lists
--- @param x list
--- @param args list
--- @return list
function list.lextend(x, args)
  for i = #args, 1, -1 do
    local X = args[i]
    assertisa(X, "table")

    for j = #X, 1, -1 do
      table.insert(x, 1, X[j])
    end
  end

  return x
end

--- Pop n elements
--- @param x list
--- @param times? number (default: 1)
--- @param pos? number
--- @return any
function list.popn(x, times, pos)
  local out = {}
  pos = pos or #x

  for i = 1, times or 1 do
    if x[i] == nil then
      return out
    end

    out[#out + 1] = table.remove(x, pos)
  end

  return out
end

--- Pop head
--- @param x list
--- @return any
function list.shift(x)
  local pos = 1

  if x[pos] == nil then
    return
  end

  return table.remove(x, pos)
end

--- Pop head n times
--- @param x list
--- @param times? number (default: 1)
--- @return any
function list.shiftn(x, times)
  local out = {}

  for _ = 1, times or 1 do
    if x[1] == nil then
      return out
    end

    out[#out + 1] = table.remove(x, 1)
  end

  return out
end

--- Pop element from list
--- @param x list
--- @param pos? number
--- @return any
function list.pop(x, pos)
  pos = pos or #x
  if x[pos] == nil then
    return
  end

  local y = table.remove(x, pos)
  return y
end

--- Remove key
--- @param x table
--- @param key any
--- @return any
function dict.remove(x, key)
  local found = x[key]
  if found == nil then
    return
  end

  x[key] = nil
  return found
end

function dict.unset(x, ks)
  return dict.get(x, ks, { unset = true })
end

--- Join list with a string
--- @param x list
--- @param sep string
--- @return string
function list.join(x, sep)
  sep = sep or " "
  return table.concat(x, sep)
end

--- Reverse list or string
--- @param x list|string
--- @return list|string
function list.reverse(x)
  if is_string(x) then
    return string.reverse(x --[[@as string]])
  end

  local res = {}
  local j = 1

  for i = #x, 1, -1 do
    res[j] = x[i]
    j = j + 1
  end

  return res
end

--- Return a sublist
--- @param x list
--- @param from? number
--- @param till? number
--- @return list?
function list.sub(x, from, till)
  local len = #x
  from = from or 1
  till = till or len
  from = from < 0 and len + (from + 1) or from
  till = till < 0 and len + (till + 1) or till

  if from > till or till > len or from < 0 then
    return
  end

  local res = {}
  for i = from, till do
    res[#res + 1] = x[i]
  end

  return res
end

--- Convert string to list of chars
--- @param x string
--- @return string[]?
function string.charlist(x)
  if type(x) ~= "string" then
    return
  end

  local y = {}
  for i = 1, #x do
    y[i] = x:sub(i, i)
  end

  return y
end

--- Modify list/string at a position. Returns nil on invalid index
--- @param X list|string returns `x` when no other args are given
--- @param at? number if `n` is not given, return everything from `at` till the end
--- @param n? number if given then pop N elements at index `at`
--- @param args any If given then insert these strings/elements at index `at`
--- @return (list|string)? popped Popped elements if any
--- @return (list|string)? new Resulting list|string
function list.splice(X, at, n, args)
  local is_s = is_string(X)
  local len = #X
  local x = is_string(X) and string.charlist(X --[[@as string]]) or X
  --- @cast x list

  if at < 0 then
    at = n + (at + 1)
  end

  if x[at] == nil then
    return
  end

  if not n then
    --- @cast x list
    local res = list.sub(x, at, len)

    if is_s then
      return list.join(res --[[@as list]], "")
    else
      return res
    end
  elseif len - n < 0 then
    return
  end

  local popped = list.popn(x, n, at)

  if #args == 0 then
    if is_s then
      return list.join(popped, ""), list.join(x, "")
    else
      return popped, x
    end
  end

  for i = #args, 1, -1 do
    list.insert(x, at --[[@as number]], args[i])
  end

  if is_s then
    return join(popped, ""), join(x, "")
  end

  return popped, x
end

--- Sort table
--- @param x list
--- @param cmp? function
--- @return list
function list.sort(x, cmp)
  table.sort(x, cmp)
  return x
end

--- Find an element in an list using BFS search
--- @param t list
--- @param item any
--- @param test? (fun(a:any, b:any): boolean)
--- @return number?
function list.index(t, item, test)
  for i = 1, #t do
    if test and test(t[i], item) then
      return i
    elseif not test and t[i] == item then
      return i
    end
  end
end

--- Apply function to each element with index
--- @param t list
--- @param f fun(index:number, elem:any)
function list.eachi(t, f)
  for _, v in ipairs(t) do
    f(_, v)
  end
end

--- Apply function to each element
--- @param t list
--- @param f fun(elem:any)
function list.each(t, f)
  for _, v in ipairs(t) do
    f(v)
  end
end

--- Apply function to each element in a table
--- @param t table
--- @param f fun(key: any, elem:any)
function dict.each(t, f)
  for _, v in pairs(t) do
    f(_, v)
  end
end

--- Return the first N-1 elements in the list
--- @param t list
--- @param n? number
--- @return list
function list.butlast(t, n)
  n = n or 1
  local len = #t
  local new = {}
  local idx = 1

  for i = 1, len - n do
    new[idx] = t[i]
    idx = idx + 1
  end

  return new
end

--- Return the first N elements
--- @param t list
--- @param n number element[s]
--- @return list
function list.head(t, n)
  n = n or 1
  local out = {}

  for i = 1, n do
    out[i] = t[i]
  end

  return out
end

--- Return the last N elements in the list
--- @param t list
--- @param n? number
--- @return list
function list.tail(t, n)
  n = n or 1

  if n == 1 then
    return { t[#t] }
  end

  n = n or 1
  local out = {}
  local len = #t
  local idx = 1

  for i = len - (n - 1), len do
    out[idx] = t[i]
    idx = idx + 1
  end

  return out
end

--- Return the last element in string|list
--- @param t string|list
--- @return any
function list.last(t)
  if is_string(t) then
    local n = #t
    return string.sub(t --[[@as string]], n, n)
  end

  return t[#t]
end

--- Return the last N-1-n elements in the  Like cdr() and nthcdr()
-- @param t list
-- @param n number of last elements. default: 1
-- @treturn list of N-1-n elements defined
function list.rest(t, n)
  n = n or 1
  local out = {}
  local idx = 1

  for i = n + 1, #t do
    out[idx] = t[i]
    idx = idx + 1
  end

  return out
end

function list.contains(x, args)
  local elems = { args }
  local found = 0
  local ks = {}
  local n = #elems

  for i = 1, #x do
    for j = 1, n do
      if elems[j] == x[i] then
        ks[#ks + 1] = i
        found = found + 1
      end
    end
  end

  if found ~= n then
    return false
  end

  return ks
end

function dict.contains(x, args)
  local elems = { args }
  local found = 0
  local ks = {}
  local n = #elems

  for key, value in pairs(x) do
    for j = 1, n do
      if elems[j] == value then
        ks[#ks + 1] = key
        found = found + 1
      end
    end
  end

  if found ~= n then
    return false
  end

  return ks
end

function dict.has(x, ks)
  return dict.get(x, ks)
end

function list.has(x, ind)
  local v = x[ind]
  return v ~= nil and v
end

list.nth = list.has

function dict.haskeys(x, ks)
  local vals = {}

  for i = 1, #ks do
    local k = ks[i]
    local v = x[k]

    if v ~= nil then
      vals[k] = v
    end
  end

  return vals
end

--- return a range of numbers
function list.range(from, till, step)
  step = step or 1
  local out = {}
  local idx = 1

  for i = from, till, step do
    out[idx] = i
    idx = idx + 1
  end

  return out
end

--- Zip two lists element-wise in the form {x, y}
function list.zip2(a, b)
  assert(type(a) == "table", "expected table, got " .. is_string(a))
  assert(type(b) == "table", "expected table, got " .. is_string(a))

  local len_a, len_b = #a, #b
  local n = len_a > len_b and len_b or len_a < len_b and len_a or len_a
  local out = {}
  for i = 1, n do
    out[i] = { a[i], b[i] }
  end

  return out
end

function dict.some(t, f)
  for _, value in pairs(t) do
    if f then
      if f(value) then
        return true
      end
    elseif value then
      return true
    end
  end

  return false
end

function dict.all(t, f)
  for _, value in pairs(t) do
    if f then
      if not f(value) then
        return false
      end
    elseif not value then
      return false
    end
  end

  return true
end

--- Check if all the elements are truthy
-- @tparam list t
-- @treturn boolean
function list.all(t, f)
  for i = 1, #t do
    if f then
      if not f(t[i]) then
        return false
      end
    elseif not t[i] then
      return false
    end
  end

  return true
end

--- Check if some elements are truthy
-- @tparam list t
-- @treturn boolean
function list.some(t, f)
  for i = 1, #t do
    if f then
      if f(t[i]) then
        return true
      end
    elseif t[i] then
      return true
    end
  end

  return false
end

--- Get the list part. This mutates the list
--- @param x table
--- @return list
function list.extract(x)
  local out = {}
  local j = 1

  for i = 1, #x do
    out[j] = x[i]
    x[i] = nil
    j = j + 1
  end

  return out
end

--- Apply a reduce to X
--- @param x list
--- @param acc any
--- @param f fun(key, value, acc): any
--- @return any
function dict.reduce(x, acc, f)
  for key, value in pairs(x) do
    acc = f(key, value, acc)
  end

  return acc
end

--- Get key of value
--- @param x table
--- @param query any
--- @param eq? fun(x,y):bool
--- @return any
function dict.index(x, query, eq)
  for key, value in pairs(x) do
    if eq then
      if eq(query, value) then
        return key
      end
    else
      if query == value then
        return key
      end
    end
  end
end

--- Apply a reduce to X
--- @param x list
--- @param acc any
--- @param f fun(a:any, acc:any): any
--- @return any
function list.reduce(x, acc, f)
  for i = 1, #x do
    acc = f(x[i], acc)
  end

  return acc
end

--- Zip lists and fill using `fillvalue` if necessary
--- @param fillvalue any
--- @param arrs list
--- @return list
function list.ziplongest(fillvalue, arrs)
  local out = {}
  local lens = {}
  local len = #arrs

  for i = 1, #arrs do
    local l = #arrs[i]
    lens[i] = l
  end

  local max = math.max(unpack(lens))

  for i = 1, max do
    out[i] = {}
    for j = 1, len do
      list.append(out[i], {arrs[j][i] or fillvalue})
    end
  end

  return out
end

--- Zip lists up till the shortest list
--- @param arrs list
--- @return list
function list.zip(arrs)
  local out = {}
  local lens = {}
  local len = #arrs

  for i = 1, #arrs do
    local l = #arrs[i]
    lens[i] = l
  end

  local min = math.min(unpack(lens))

  for i = 1, min do
    out[i] = {}
    for j = 1, len do
      list.append(out[i], {arrs[j][i]})
    end
  end

  return out
end

list.cdr = list.rest

function string.contains(x, args)
  for i = 1, #args do
    if not x:match(args[i]) then
      return false
    end
  end

  return true
end

local function _flatten(x, depth, _len, _current_depth, _result)
  depth = depth or 1
  _len = _len or #x
  _current_depth = _current_depth or 1
  _result = _result or {}

  if _current_depth > depth then
    return _result
  end

  for i = 1, _len do
    local elem = x[i]
    if is_table(elem) then
      _flatten(x[i], depth, _len, _current_depth + 1, _result)
    else
      list.append(_result, {elem})
    end
  end

  return _result
end

--- Flatten list
--- @param x list
--- @param depth? number (default: 1)
--- @return list
function list.flatten(x, depth)
  return _flatten(x, depth)
end

--- Partition dict
--- @param x table
--- @param fn fun(x):bool elements that succeed the callable will be placed in `result[1]` and the failures in `result[2]`
--- @return list result
function dict.partition(x, fn)
  assertisa(fn, "callable")

  local result = { {}, {} }

  for key, value in pairs(x) do
    if fn(value) then
      result[1][key] = value
    else
      result[2][key] = value
    end
  end

  return result
end

function list.dropwhile(x, fn)
  local out = {}
  for i = 1, #x do
    if not fn(x[i]) then
      out[#out + 1] = x[i]
    end
  end

  return out
end

function dict.dropwhile(x, fn)
  local out = {}
  for key, value in pairs(x) do
    if not fn(key, value) then
      out[key] = value
    end
  end

  return out
end

function dict.onlyhas(x, args)
  local ks = { args }
  local hasks = keys(x)

  if #ks ~= hasks then
    return false
  end

  for i = 1, #ks do
    if not x[ks[i]] then
      return false
    end
  end

  return true
end

function is_size(x, n)
  return size(x) == n
end

function is_length(x, n)
  return length(x) == n
end

--- Partition/chunk list
--- > local function greater_than_2(x) return x > 2 end
--- > partition({1, 2, 3, 4, 5}, greater_than_2) -- {{3, 4, 5}, {1, 2}}
--- > partition({1, 2, 3, 4}, 3) -- {{1, 2, 3}, {4}}
--- @param x list
--- @param fun_or_num number|function If callable then elements that succeed the callable will be placed in `result[1]` and the failures in `result[2]`. If number than chunk list
--- @return list result
function list.partition(x, fun_or_num)
  assertisa(fun_or_num, union("number", "callable"))

  if is_callable(fun_or_num) then
    local result = { {}, {} }

    for i = 1, #x do
      if fun_or_num(x[i]) then
        list.append(result[1], {x[i]})
      else
        list.append(result[2], {x[i]})
      end
    end

    return result
  end

  local is_t = is_table(x)
  local len = #x
  local chunk_size = math.ceil(len / fun_or_num)
  local result = {}
  local k = 1

  for i = 1, len, chunk_size do
    result[k] = {}

    if is_t then
      for j = 1, chunk_size do
        result[k][j] = x[i + j - 1]
      end
    else
      result[k] = string.sub(x, --[[@as string]] i, i + chunk_size - 1)
    end

    k = k + 1
  end

  return result
end

--- Chunk list
--- > chunk_every({1, 2, 3, 4}, 2) -- {{1, 2}, {3, 4}}
--- @param x list
--- @param chunk_size? number (default: 2)
--- @return list
function list.chunk(x, chunk_size)
  chunk_size = chunk_size or 2
  assertisa(chunk_size, "number")
  return list.partition(x, chunk_size)
end

--- Get key-value pairs from a table
--- @param t table
--- @return table
function dict.items(t)
  local out = {}
  local i = 1

  for key, val in pairs(t) do
    out[i] = { key, val }
    i = i + 1
  end

  return out
end

function dict.lmerge(x, args)
  local cache = {}

  for i = 1, #args do
    local X = x
    local Y = args[i]
    local queue = {}

    if not is_table(Y) then
      error(i .. ': expected table, got ' .. type(Y))
    end

    while X and Y do
      for key, value in pairs(Y) do
        local x_value = X[key]

        if is_table(value) then
          if is_table(x_value) then
            if not cache[value] and not cache[x_value] then
              queue[#queue+1] = {x_value, value}
            else
              cache[value] = true
              cache[x_value] = true
            end
          elseif is_nil(x_value) then
            X[key] = value
          end
        elseif is_nil(x_value) then
          X[key] = value
        end
      end

      local len = #queue
      if len ~= 0 then
        X, Y = unpack(queue[len])
        queue[len] = nil
      else
        break
      end
    end
  end

  return x
end

function dict.merge(x, args)
  local cache = {}

  for i = 1, #args do
    local X = x
    local Y = args[i]
    local queue = {}

    if not is_table(Y) then
      error(i .. ': expected table, got ' .. type(Y))
    end

    while X and Y do
      for key, value in pairs(Y) do
        local x_value = X[key]

        if is_table(value) then
          if is_table(x_value) then
            if not cache[value] and not cache[x_value] then
              queue[#queue+1] = {x_value, value}
            else
              cache[value] = true
              cache[x_value] = true
            end
          else
            X[key] = value
          end
        else
          X[key] = value
        end
      end

      local len = #queue
      if len ~= 0 then
        X, Y = unpack(queue[len])
        queue[len] = nil
      else
        break
      end
    end
  end

  return x
end


--- Extract the non-list part of the table
--- @param x table
--- @return table, list
function dict.extract(x)
  local list_part = list.extract(x)
  local dict_part = x

  return dict_part, list_part
end

--- Create a dict from kv pairs
--- @param zipped list
--- @return table
function dict.fromzipped(zipped)
  local out = {}

  list.each(zipped, function(x)
    out[first(x)] = cdr(x)
  end)

  return out
end

--- Create a dict from list of keys
--- @param X list
--- @param default? any (default: true)
--- @return table
function dict.fromkeys(X, default)
  local res = {}

  for _, x in ipairs(X) do
    if default then
      res[x] = default()
    else
      res[x] = true
    end
  end

  return res
end

--- @class dict.groupby.rule
--- @field [1] string
--- @field [2] string|string[]

--- Group keys by lua patterns
--- @param x table
--- @param spec dict.groupby.rule[]
--- @return table<string,any>
function dict.groupby(x, spec)
  local matched = { rest = {} }
  local patterns = {}

  list.each(spec --[[@as list]], function(pattern)
    local name
    name, pattern = unpack(pattern)

    if not pattern then
      error("no pattern provided for group " .. name)
    end

    list.each(to_list(pattern), function(pat)
      if patterns[pat] then
        error(sprintf("pattern %s already exists for %s", pat, name))
      end

      patterns[pat] = name
    end)
  end)

  local times_matched = {}
  dict.each(x, function(key, val)
    dict.each(patterns, function(pat, name)
      times_matched[key] = times_matched[key] or 0
      if key:match(pat) then
        patterns[pat] = nil
        matched[name] = matched[name] or {}
        matched[name][key] = val
        times_matched[key] = times_matched[key] + 1
      end
    end)
  end)

  dict.each(times_matched, function(key, times)
    if times == 0 then
      matched.rest[key] = x[key]
    end
  end)

  return matched
end

function list.withindex(x)
  local out = {}
  for i = 1, #x do
    out[i] = { { i, x[i] } }
  end

  return out
end

function ref(x)
  if not is_table(x) then
    if is_string(x) or is_number(x) then
      return x
    end

    return is_string(x)
  end

  local MT = mtget(x)
  if not MT then
    return
  end

  local _tostring = MT.__tostring
  MT.__tostring = nil

  mtset(x, MT)

  local ref = tostring(x)

  MT.__tostring = _tostring
  mtset(x, MT)

  return ref
end

--- string A < string B?
--- @param a string
--- @param b string
--- @param desc? bool if passed then return false at a < b else at a > b
function strcmp(a, b, desc)
  local a_len = #a
  local b_len = #b
  local max = (a_len > b_len and b_len) or a_len

  for i = 1, max do
    local a_byte = string.byte(a:sub(i, i)) or -1
    local b_byte = string.byte(b:sub(i, i)) or -1

    if desc then
      if b_byte < a_byte then
        return true
      else
        return false
      end
    else
      if b_byte < a_byte then
        return true
      else
        return false
      end
    end
  end
end

--- @param x table
--- @param value_type any
--- @param key_type any
--- @see istype
--- @return boolean
function dict.is_a(x, value_type, key_type)
  for key, value in pairs(x) do
    if key_type and value_type and not is_a(value, value_type) and not is_a(key, key_type) then
      return false
    elseif value_type and not is_a(value, value_type) then
      return false
    elseif key_type and not is_a(key, key_type) then
      return false
    end
  end

  return true
end

--- @param x list
--- @param tp string|function|table
--- @see istype
--- @return boolean
function list.is_a(x, tp)
  return list.all(x, function(elem)
    return is_a(elem, tp)
  end)
end

--- Fetch a list of keys
--- @param x table
--- @param args any
--- @return list|table
function dict.fetch(x, ks)
  local out = {}

  for i = 1, #ks do
    assertisa.table(ks[i])
    out[i] = dict.get(x, ks[i])
  end

  return out
end

local function dicteq(a, b, absolute, state, ok)
  assertisa.table(a)
  assertisa.table(b)

  ok = ok or false

  for key, b_value in pairs(b) do
    local a_value = a[key]

    if is_nil(a_value) then
      if absolute then
        return false
      end

      state[key] = false
    elseif is_table(a_value) and is_table(b_value) then
      state[key] = {}
      state = state[key]

      return dicteq(a_value, b_value, absolute, state, ok)
    elseif a_value ~= b_value then
      if absolute then
        return false
      else
        state[key] = false
      end
    elseif not absolute then
      state[key] = true
    else
      ok = true
    end
  end

  return ok
end

--- compare A and B or is A == B
--- @param a dict
--- @param b dict
--- @param absolute? boolean If passed then do not return a boolean dict of compared times from keys of B
--- @return dict|boolean
function dict.eq(a, b, absolute)
  if absolute then
    return dicteq(a, b, true)
  end

  local result = {}
  dicteq(a, b, false, result)

  return result
end

--- compare A and B or is A ~= B
--- @param a dict
--- @param b dict
--- @param absolute? boolean If passed then do not return a boolean dict of compared times from keys of B
--- @return dict|boolean
function dict.ne(a, b, absolute)
  return not dict.eq(a, b, absolute)
end

--- @param x table
--- @param fill? fun(): any
--- @return list?
function list.fix(x, fill)
  if not is_table(x) then
    return
  end

  local ks = keys(x)

  list.sort(ks, function (x, y)
    if is_number(x) and is_number(y) then
      return x > y
    end

    return false
  end)

  local max = ks[1]
  if not ks[1] then
    return
  end

  for i=1, max do
    if x[i] == nil then
      if fill then
        x[i] = fill()
        assert(x[i] ~= nil, 'fill() cannot return nil at index ' .. i)
      else
        x[i] = false
      end
    end
  end

  return x
end

--- Remove all noninteger elements and convert dict to list 
--- @param x table
--- @param fill? fun(): any 
--- @return table?
function dict.to_list(x, fill)
  if not is_table(x) then
    return
  end

  for key, _ in pairs(x) do
    if not is_number(key) then
      x[key] = nil
    end
  end

  return list.fix(x, fill)
end


function list.get(x, ks)
  local max = #ks
  local tmp = x

  for i=1, #ks-1 do
    local k = ks[i]
    local v = tmp[k]

    if not is_table(v) then
      return
    else
      tmp = v
    end
  end

  return tmp[ks[max]]
end

function list.fetch(x, ks)
  assertisa.table(x)

  local res = {}
  for i=1, #ks do
    assertisa.table(ks[i])
    res[ks[i]] = list.get(x, ks[i])
  end

  return res
end
