local _class = require "pl.class"
Map = Map or require "pl.Map"
OrderedMap = OrderedMap or require "pl.OrderedMap"
MultiMap = MultiMap or require "pl.MultiMap"
List = require "pl.List"
Date = Date or require "pl.Date"
user = user or {}
concat = table.concat
substr = string.sub
keys = vim.tbl_keys
values = vim.tbl_values
copy = vim.deepcopy
flatten = vim.tbl_flatten
stdpath = vim.fn.stdpath
isempty = vim.tbl_is_empty
islist = vim.tbl_islist
dump = vim.inspect
trim = vim.trim
deepcopy = vim.deepcopy
command = vim.api.nvim_create_user_command
autocmd = vim.api.nvim_create_autocmd
augroup = vim.api.nvim_create_augroup
bindkeys = vim.keymap.set
remkeys = vim.keymap.del
TYPES = {
  s = "string",
  t = "table",
  u = "userdata",
  n = "number",
  f = "callable",
  b = "boolean",
  c = "class",
  string = "string",
  table = "table",
  userdata = "userdata",
  number = "number",
  boolean = "boolean",
  ["function"] = "callable",
  callable = "callable",
  Set = "Set",
  Map = "Map",
  OrderedMap = "OrderedMap",
  MultiMap = "MultiMap",
  Date = "Date",
  Lang = "Lang",
  Colorscheme = "Colorscheme",
  REPL = "REPL",
  Buffer = "Buffer",
  Autocmd = "Autocmd",
  Keybinding = "Keybinding",
  A = "Autocmd",
  K = "Keybinding",
  B = "Buffer",
  Process = "Process",
}

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
List.iappend = iappend

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
List.shift = shift

function unshift(t, ...)
  for idx, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end
List.unshift = unshift

local function param_error_s(name, expected, got)
  return string.format("%s: expected %s got %s", name, tostring(expected), tostring(got))
end

function class(name, base)
  assert(type(name) == "string", param_error_s("name", "string", name))
  assert(name:match "^[A-Za-z0-9_]+$", "name: Should only contain alphanumeric characters")
  assert(substr(name, 1, 1):match "[A-Z]", "name: Should start with a capital letter")

  return _class[name](base)
end
class "Set"

function pp(...)
  local final_s = ""

  for _, obj in ipairs { ... } do
    if type(obj) == "table" then
      obj = vim.inspect(obj)
    end
    final_s = final_s .. tostring(obj) .. "\n\n"
  end

  vim.api.nvim_echo({ { final_s } }, false, {})
end

function class_of(e)
  if type(e) ~= "table" then
    return false
  end
  if e._class then
    return e._class
  end
  local mt = getmetatable(e) or {}
  if mt._class then
    return mt._class
  end
end

function is_instance(e, cls)
  if type(e) ~= "table" then
    return false
  end
  if type(cls) ~= "table" then
    return false
  end

  return class_of(e) == class_of(cls)
end

function is_callable(t)
  local k = type(t)
  if k ~= "table" and k ~= "function" then
    return false
  elseif k == "function" then
    return true
  end

  local mt = getmetatable(t)
  if mt then
    if mt.__call then
      return true
    end
  end
  return false
end

function get_class(e)
  if type(e) == "string" then
    local g = _G[e]
    if type(g) == "table" then
      return (class_of(g) or false)
    end
  end

  if type(e) ~= "table" then
    return false
  end
  return (class_of(e) or false)
end

function is_class(e)
  if type(e) ~= "table" then
    return false
  end

  return get_class(e) or false
end

function is_table(obj)
  return type(obj) == "table"
end

function class_name(obj)
  cls = get_class(obj)
  if cls then
    return cls._name
  end
  return false
end

function is_pure_table(t)
  return is_table(t) and not getmetatable(t)
end

function typeof(x)
  if type(x) == "table" then
    local cls = get_class(x)
    if cls then
      return cls
    else
      local mt = getmetatable(x) or {}
      if mt.__call then
        return "callable"
      end
      return "table"
    end
  elseif type(x) == "function" then
    return "callable"
  end

  return type(x)
end

local _is_a = function(e, k)
  if TYPES[k] then
    k = TYPES[k]
  end

  local e_cls, k_cls
  if k == "table" or k == table or k == "string" or k == string then
    if k == table then
      k = "table"
    elseif k == string then
      k = "string"
    end
    return type(e) == k
  elseif _G[k] then
    local g = _G[k]
    e_cls = get_class(e)
    k_cls = get_class(g)
  else
    e_cls = get_class(e)
    k_cls = get_class(k)
  end

  if e_cls and k_cls then
    local e_name, k_name = class_name(e_cls), class_name(k_cls)
    if e_name and k_name then
      return e_name == k_name
    end
    return e_cls == k_cls
  elseif e_cls and k == "table" then
    return true
  elseif k_cls then
    return false
  elseif k == "callable" then
    return is_callable(e)
  elseif k == "class" then
    return is_class(e)
  end

  return type(e) == k
end

is_a = setmetatable({}, {
  __call = function(self, e, ...)
    local args = { ... }
    local out = false
    for _, tp in ipairs(args) do
      out = out or self[tp](e)
    end
    return out
  end,

  -- Only works for native datatypes + callables
  __index = function(_, k)
    return function(e)
      return _is_a(e, k)
    end
  end,
})

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

---
-- Mapping functions
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

MultiMap.filter = tfilter
MultiMap.each = teach
MultiMap.map = tmap
MultiMap.grep = tgrep
MultiMap.items = items
OrderedMap.filter = tfilter
OrderedMap.each = teach
OrderedMap.map = tmap
OrderedMap.grep = tgrep
OrderedMap.items = items
Map.filter = tfilter
Map.each = teach
Map.map = tmap
Map.grep = tgrep
Map.items = items
List.each = each
List.map = map
List.grep = grep
List.filter = filter
List.ifilter = ifilter
List.ieach = ieach
List.imap = ieach
List.igrep = igrep
List.index = index

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

function split(s, delim)
  return vim.split(s, delim or " ")
end

function Set:contains(e)
  return self[e] ~= nil
end

function Set:add(element)
  assert(element ~= nil, "Element cannot be nil")

  if not self[element] then
    self[element] = element
  end

  return self
end

-- Will not work with userdata
function Set:remove(element)
  assert(element ~= nil, "Element cannot be nil")

  local value = deepcopy(self[element])
  self[element] = nil

  return value
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

function tolist(x, force)
  if is_a(x, Set) then
    return x:tolist()
  end

  if force or type(x) ~= "table" then
    return { x }
  end

  return x
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

Set.each = each
Set.map = map
Set.grep = grep
Set.filter = filter
Set.ifilter = ifilter
Set.ieach = ieach
Set.imap = ieach
Set.igrep = igrep

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

function compare(a, b, callback)
  local depth, compared, state = 1, {}, nil
  state = compared

  local function _compare(a, b)
    local ks_a = Set(keys(a))
    local ks_b = Set(keys(b))
    local common =  ks_a:intersection(ks_b)
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

function is(type_spec)
  type_spec = map(tolist(type_spec), function(i)
    return TYPES[i]
  end)

  return setmetatable({}, {
    __call = function(_, e)
      local invalid = {}
      for _, t in ipairs(type_spec) do
        if not is_a(e, t) then
          invalid[#invalid + 1] = t
        end
      end

      if #invalid == #type_spec then
        return false, string.format("expected %s, got %s", table.concat(invalid, "|"), tostring(e))
      end

      return true
    end,
    required = table.concat(type_spec, "|")
  })
end

local function _validate(a, b)
  opts = opts or {}
  local callback = opts.callback

  local function _compare(a, b)
    local nonexistent = a.__nonexistent == nil and true
    local level_name = a.__table or tostring(a)
    a.__nonexistent = nil
    a.__table = nil
    local optional = {}
    local ks_a = keys(a)
    local ks_b = keys(b)

    ieach(ks_a, function(idx, k)
      k = tostring(k)
      local opt = k:gsub('^%?', '')
      if opt then
        optional[opt] = true
      end
      if opt:match('^[0-9]+$') then
        opt = tonumber(opt)
      end
      ks_a[idx] = opt
    end)

    ks_a = Set(ks_a)
    ks_b = Set(ks_b)
    local common =  ks_a:intersection(ks_b)
    local missing = ks_a:difference(ks_b)
    local foreign = ks_b:difference(ks_a)
    
    assert(
      missing:len() == 0, 
      string.format('%s: missing keys: %s', level_name, dump(missing:values()))
    )

    if not nonexistent then
      assert(
        foreign:len() == 0, 
        string.format('%s: unrequired keys: %s', level_name, dump(foreign:values()))
      )
    end

    each(common, function(key)
      level_name = level_name  .. '.' .. key
      local x, y = a[key], b[key]

      if optional[key] and b == nil then return end

      local x_tp, y_tp = typeof(x), typeof(y)
      x_tp = tostring(x_tp)
      y_tp = tostring(y_tp)
      if is_a.t(x_tp) and is_a.t(y_tp) then
        assert(
          x_tp == y_tp,
          string.format('%s: expected %s, got %s', level_name, x_tp, y)
        )
      elseif is_a.t(x) and is_a.t(y) then
        x.__table = key
        _compare(x, y)
      elseif is_a.f(x) then
        local ok, msg = x(y)
        if not ok then
          error(level_name .. ':' .. ' ' .. msg)
        end
      else
        x = TYPES[x] or x
        assert(
          is_a(y, x),
          string.format('%s: expected %s, got %s', level_name, x, y)
        )
      end
    end)
  end

  _compare(a, b)
end

function validate(type_spec)
  teach(type_spec, function(display, spec)
    local tp, param = unpack(spec)
    if display:match('^%?') and param == nil then 
      return
    end
    _validate( { __table = display, tp }, { param })
  end)
end


function whereis(bin, regex)
  local out = vim.fn.system("whereis " .. bin .. [[ | cut -d : -f 2- | sed -r "s/(^ *| *$)//mg"]])
  out = trim(out)
  out = split(out, " ")

  if isblank(out) then
    return false
  end

  if regex then
    for _, value in ipairs(out) do
      if value:match(regex) then
        return value
      end
    end
  end
  return out[1]
end

function sprintf(fmt, ...)
  local args = { ... }

  for i = 1, #args do
    if is_a.t(args[i]) then
      args[i] = dump(args[i])
    end
  end

  return string.format(fmt, unpack(args))
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
List.extend = extend

-- For multiple patterns, OR matching will be used
function match(s, ...)
  for _, value in ipairs { ... } do
    local m = s:match(value)
    if m then
      return m
    end
  end
end

-- If varname in [varname] = var is prefixed with '!' then it will be overwritten
function global(vars)
  for var, value in pairs(vars) do
    if var:match "^!" then
      var = var:gsub("^!", "")
      _G[var] = value
    elseif _G[var] == nil then
      _G[var] = value
    end
    globals[var] = value
  end
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

function butlast(t)
  local new = {}

  for i = 1, #t - 1 do
    new[i] = t[i]
  end

  return new
end
List.butlast = butlast

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
List.last = last

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
List.first = first
List.head = first

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
List.rest = rest
List.tail = rest

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

function rpartial(f, ...)
  local outer = { ... }
  return function(...)
    local inner = { ... }
    local len = #outer
    for idx, a in ipairs(outer) do
      inner[len + idx] = a
    end

    return f(unpack(inner))
  end
end

function partial(f, ...)
  local outer = { ... }
  return function(...)
    local inner = { ... }
    local len = #outer
    for idx, a in ipairs(inner) do
      outer[len + idx] = a
    end

    return f(unpack(outer))
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
List.get = get
Map.get = get

function printf(...)
  print(sprintf(...))
end

function with_open(fname, mode, callback)
  local fh = io.open(fname, mode)
  local out = nil
  if fh then
    out = callback(fh)
    fh:close()
  end

  return out
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

function buffer_has_keymap(bufnr, mode, lhs)
  bufnr = bufnr or 0
  local keymaps = vim.api.nvim_buf_get_keymap(bufnr, mode)
  lhs = lhs:gsub("<leader>", vim.g.mapleader)
  lhs = lhs:gsub("<localleader>", vim.g.maplocalleader)

  return index(keymaps, lhs, function(t, item)
    return t.lhs == item
  end)
end

function joinpath(...)
  return table.concat({ ... }, "/")
end

function basename(s)
  s = vim.split(s, "/")
  return s[#s]
end

function visualrange(bufnr)
  return vim.api.nvim_buf_call(bufnr or vim.fn.bufnr(), function()
    local _, csrow, cscol, _ = unpack(vim.fn.getpos "'<")
    local _, cerow, cecol, _ = unpack(vim.fn.getpos "'>")
    if csrow < cerow or (csrow == cerow and cscol <= cecol) then
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cecol, {})
    else
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cscol, {})
    end
  end)
end

function nvimerr(...)
  for _, s in ipairs { ... } do
    vim.api.nvim_err_writeln(s)
  end
end

-- If multiple keys are supplied, the table is going to be assumed to be nested
function haskey(tbl, ...)
  return (get(tbl, { ... }))
end
contains = haskey

function makepath(t, ...)
  return get(t, { ... }, true)
end
Map.makepath = makepath
OrderedMap.makepath = makepath
MultiMap.makepath = makepath

function req(require_string, do_assert)
  local ok, out = pcall(require, require_string)
  if ok then
    return out
  end

  local no_file = false
  no_file = out:match "^module '[^']+' not found"

  if no_file then
    out = "Could not require " .. require_string
  end

  makepath(user, "logs")
  append(user.logs, out)
  logger:debug(out)

  if do_assert then
    error(out)
  end
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
Map.merge = merge
OrderedMap.merge = merge
MultiMap.merge = merge
OrderedMap.lmerge = lmerge
MultiMap.lmerge = lmerge
Map.lmerge = lmerge

function apply(f, args)
  return f(unpack(args))
end

function items(t)
  validate {
    tbl = { { "Map", "OrderedMap", "table", "MultiMap" }, t },
  }

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

function glob(d, expr, nosuf, alllinks)
  nosuf = nosuf == nil and true or false
  return vim.fn.globpath(d, expr, nosuf, true, alllinks) or {}
end

function get_font()
  font = vim.o.guifont:match "^([^:]+)"
  height = vim.o.guifont:match "h([0-9]+)" or 12
  return font, height
end

function set_font(font, height)
  validate {
    ["?font"] = { "s", font },
    ["?height"] = { "n", height },
  }

  local current_font, current_height = get_font()
  if not font then
    font = current_font
  end
  if not height then
    height = current_height
  end

  font = font:gsub(" ", "\\ ")
  vim.cmd("set guifont=" .. sprintf("%s:h%d", font, height))
end
