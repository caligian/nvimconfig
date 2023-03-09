local _class = require "pl.class"
types = require "pl.types"
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

_class.Set()

local function param_error_s(name, expected, got)
  return string.format("%s: expected %s got %s", name, tostring(expected), tostring(got))
end

function class(name, base)
  assert(type(name) == "string", param_error_s("name", "string", name))
  assert(name:match "^[A-Za-z0-9_]+$", "name: Should only contain alphanumeric characters")
  assert(substr(name, 1, 1):match "[A-Z]", "name: Should start with a capital letter")

  return _class[name](base)
end

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

function index(t, item, test)
  assert(type(t) == "table", "t is not a table")

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
      return (rawget(g, "_class") or mtget(g, "_class") or false)
    end
  end

  if type(e) ~= "table" then
    return false
  end
  local out = (e._class or mtget(e, "_class") or false)
  return out
end

function is_class(e)
  if type(e) ~= "table" then
    return false
  end

  local cls = get_class(e)
  if cls then
    return cls
  end
  return false
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
  return is_table(t) and not is_class(t)
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

local _types = {
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

local _is_a = function(e, k)
  if _types[k] then
    k = _types[k]
  end

  local e_cls, k_cls
  if _G[k] then
    local g = _G[k]
    e_cls = get_class(e)
    k_cls = get_class(g)
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

-- This needs a rewrite
is_a = setmetatable({}, {
  __call = function(_, e, k)
    return _is_a(e, k)
  end,

  -- Only works for native datatypes + callables
  __index = function(_, k)
    return function(e)
      return _is_a(e, k)
    end
  end,
})

local function get_iterator(t, is_dict)
  assert(
    is_a.Map(t) or is_a.OrderedMap(t) or is_a.List(t) or is_a.Set(t) or is_a.table(t),
    "t: Map|OrderedMap|List|Set|table expected, got " .. tostring(t)
  )

  if is_a.Map(t) or is_a.OrderedMap(t) or is_a.List(t) or is_a.Set(t) then
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

function teach(t, f)
  for key, value in get_iterator(t, true)(t) do
    f(key, value)
  end
end

function map(t, f)
  local out = {}
  for key, value in get_iterator(t)(t) do
    out[key] = f(value)
  end

  return out
end

function tmap(t, f)
  local out = {}
  for key, value in get_iterator(t, true)(t) do
    out[key] = f(key, value)
  end

  return out
end

function filter(t, f)
  local filtered = {}
  local i = 1

  for _, value in get_iterator(t)(t) do
    local out = f(value)
    if out then
      filtered[i] = out
      i = i + 1
    end
  end

  return filtered
end

function grep(t, f)
  local filtered = {}
  local i = 1

  for _, value in get_iterator(t)(t) do
    local out = f(value)
    if out then
      filtered[i] = value
      i = i + 1
    end
  end

  return filtered
end

function tgrep(t, f)
  local filtered = {}

  for key, value in get_iterator(t, true)(t) do
    local out = f(value)
    if out then
      filtered[key] = value
    end
  end

  return filtered
end

function tfilter(t, f)
  local filtered = {}

  for key, value in get_iterator(t, true)(t) do
    local out = f(key, value)
    if out then
      filtered[key] = out
    end
  end

  return filtered
end

function each(t, f)
  for _, value in get_iterator(t)(t) do
    f(value)
  end
end

function ieach(t, f)
  for idx, value in get_iterator(t)(t) do
    f(idx, value)
  end
end

function imap(t, f)
  local out = {}
  for index, value in get_iterator(t)(t) do
    out[index] = f(index, value)
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
  assert(type(s) == "string" or type(s) == "table", "Need a string or a table")

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
  assert(type(s) == "string", "s is not a string")

  delim = delim or " "
  assert(type(delim) == "string", "delim is not a string")

  return vim.split(s, delim)
end

function Set:_init(x)
  assert(is_a.t(x) or is_a.Set(x), "x is not a table/Set")

  if typeof(x) == Set then
    self.set = deepcopy(x.set)
  else
    self.set = {}
  end

  for _, v in ipairs(x) do
    self.set[v] = true
  end

  return self
end

function Set:contains(e)
  return self.set[e] ~= nil
end

function Set:add(element)
  assert(element ~= nil, "Element cannot be nil")

  if not self.set[element] then
    self.set[element] = true
  end

  return self
end

-- Will not work with userdata
function Set:remove(element)
  assert(element ~= nil, "Element cannot be nil")

  local value = deepcopy(self.set[element])
  self.set[element] = nil

  return value
end

function Set:tolist()
  local t = {}
  local i = 1
  for x, _ in pairs(self.set) do
    t[i] = x
    i = i + 1
  end

  return t
end

function Set:copy()
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
  local X = self.set
  local out = Set {}

  for _, Y in ipairs { ... } do
    -- For performance reasons :(
    assert(is_a.t(Y) or is_a.Set(Y), "Y should either be an array or a Set")

    Y = Set(Y).set
    for x, _ in pairs(X) do
      if not Y[x] then
        out:add(x)
      end
    end
  end

  return out
end

function Set:intersection(...)
  local X = self.set
  local out = Set {}

  for _, Y in ipairs { ... } do
    assert(is_a.t(Y) or is_a.Set(Y), "Y should either be an array or a Set")
    Y = Set(Y).set

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

function Set:complement(...)
  local X = self.set
  local out = Set {}
  local Z = self:intersection(...).set

  for x, _ in pairs(X) do
    if not Z[x] then
      out:add(x)
    end
  end

  return out
end

function Set:union(...)
  local X = self.set
  local out = Set {}

  for _, Y in ipairs { ... } do
    assert(is_a.t(Y) or is_a.Set(Y), "Y should either be an array or a Set")
    Y = Set(Y).set

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
    local copy = self:copy()
    copy:remove(b)
    return copy
  end
  return self:difference(b)
end

function Set:__add(b)
  if not is_a(b, Set) and not is_a(b, "t") then
    return Set(self:add(b).set)
  end
  return self:union(b)
end

function Set:__pow(b)
  if not is_a(b, Set) and not is_a(b, "t") then
    return Set(self:add(b).set)
  end
  return self:intersection(b)
end

function Set:sort(f)
  return table.sort(self:tolist(), f)
end

function Set:values()
  return keys(self.set)
end

function Set:each(f)
  for x, _ in pairs(self.set) do
    f(x)
  end
  return self
end

function Set:filter(f)
  local out = Set {}
  for x, _ in pairs(self.set) do
    if f(x) then
      out:add(x)
    end
  end

  return out
end

function Set:map(f)
  local out = Set {}
  for x, _ in pairs(self.set) do
    local o = f(x)
    if o ~= nil then
      out:add(o)
    end
  end

  return out
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

function Set:len()
  return #(keys(self.set))
end

function Set:issubset(other)
  other = Set(other)
  return self:difference(other):len() == 0
end

function Set:issuperset(other)
  other = Set(other)
  return other:difference(self):len() == 0
end

local function _compare_level(a, b, compared, opts, depth)
  opts = opts or {}
  local maxdepth = opts.depth
  if maxdepth and maxdepth < depth then
    return compared
  end

  depth = depth or 1
  local ks_a = Set(keys(a))
  local ks_b = Set(keys(b))
  local common = ks_a ^ ks_b
  local missing = ks_a - ks_b
  local foreign = ks_b - ks_a
  opts = opts or {}
  local id = opts.id
  local callback = opts.callback
  local test = opts.test
  local later = {}
  local allow_nonexistent = opts.allow_nonexistent == nil and true or opts.allow_nonexistent
  local allow_missing = opts.allow_missing == nil and true or opts.allow_missing
  local level_name = opts.name or tostring(a)

  if level_name then
    if not is_a.s(level_name) then
      error("level_name: string expected, got " .. level_name)
    end
  end

  if not allow_nonexistent and foreign:len() ~= 0 then
    error(string.format("%s(extra keys supplied): ", level_name, dump(foreign:values())))
  end

  missing = missing:filter(function(x)
    x = tostring(x)
    if x:match "^%?" then
      return false
    end
    return true
  end)

  if not allow_missing and missing:len() ~= 0 then
    error(string.format("%s(missing keys): %s", level_name, dump(missing:values())))
  end

  missing:map(function(k)
    compared[k] = false
  end)

  common:each(function(key)
    local x, y = a[key], b[key]
    local current_level = string.format("%s.%s", level_name, key)

    if is_pure_table(x) and is_pure_table(y) and x ~= a and y ~= b then
      compared[key] = {}
      opts.name = current_level
      _compare_level(x, y, compared[key], opts, depth + 1)
    elseif callback then
      local out = callback(current_level, x, y)
      if out ~= nil then
        compared[key] = out
      end
    else
      compared[key] = x == y
    end
  end)

  return compared
end

function compare(t1, t2, opts)
  return _compare_level(t1, t2, {}, opts or {})
end

function validate(params)
  assert(is_a.t(params), "params: expected table, got " .. tostring(params))

  for display, value in pairs(params) do
    assert(is_a.t(value) and #value >= 1, "spec: {type, var}")

    local tp, param = unpack(value)
    if _types[tp] then
      tp = _types[tp]
    end

    local optional = display:match "^%?"
    display = display:gsub("^%?", "")

    if param == nil and not optional then
      error(display .. ": expected " .. tostring(tp) .. " got nil")
    end

    if is_pure_table(tp) and is_pure_table(param) then
      local allow_nonexistent = tp.__allow_nonexistent
      tp.__allow_nonexistent = nil

      compare(tp, param, {
        allow_nonexistent = allow_nonexistent,
        allow_optional = true,
        name = display,
        callback = function(id, check, var)
          if not is_a.f(check) and not is_a.t(check) then
            check = type(check)
          end

          if is_a.f(check) then
            local out = check(var)
            local msg = string.format("callback failed for %s", id, tostring(var))
            local ok = out
            if is_a.t(out) then
              ok = out[1]
              msg = out[2] or msg
            end
            assert(ok, id .. ": " .. msg)
          elseif is_a.t(check) then
            local ok = nil
            for i = 1, #check do
              ok = ok or is_a(var, check[i])
            end
            assert(ok, string.format("%s: expected %s, got %s", id, dump(check), tostring(var)))
          else
            assert(
              is_a(var, check),
              string.format("%s: expected %s, got %s", id, check, tostring(var))
            )
          end
        end,
      })
    elseif is_callable(tp) then
      if param == nil and optional then
        return
      end
      assert(tp(param), string.format("%s: callable failed for %s", display, tostring(param)))
    elseif is_pure_table(tp) then
      if param == nil and optional then
        return
      end
      local ok = nil
      for i = 1, #tp do
        local k = tp[i]
        if _types[k] then
          tp[i] = k
        end
        ok = ok or is_a(param, tp[i])
      end
      assert(ok, string.format("%s: expected %s, got %s", display, dump(tp), tostring(var)))
    else
      if not optional then
        assert(
          is_a[tp](param),
          string.format("%s: %s expected, got %s", display, tostring(tp), tostring(param))
        )
      elseif param ~= nil then
        assert(
          is_a[tp](param),
          string.format("%s: %s expected, got %s", display, tostring(tp), tostring(param))
        )
      end
    end
  end
end

function whereis(bin, regex)
  validate {
    command = { "string", bin },
    ["?regex"] = { "string", regex },
  }

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

function append(t, ...)
  local idx = #t
  for i, value in ipairs { ... } do
    t[idx + i] = value
  end

  return t
end

function iappend(t, idx, ...)
  validate {
    ["?index"] = { "n", idx },
  }

  for _, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function shift(t, times)
  validate {
    ["?times"] = { "n", times },
  }

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

function unshift(t, ...)
  validate { t = { "t", t } }
  for idx, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

-- For multiple patterns, OR matching will be used
function match(s, ...)
  validate { s = { "s", s } }

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

function makepath(t, ...)
  return get(t, { ... }, true)
end

function req(req, do_assert)
  local ok, out = pcall(require, req)

  if is_a.s(out) then
    out = split(out, "\n")
    out = grep(out, function(x)
      if x:match "^%s*no file '" or x:match "no field package.preload" or x:match "lazy_loader" then
        return false
      end
      return true
    end)

    out = concat(out, "\n")
  end

  if not ok then
    makepath(user, "logs")
    append(user.logs, out)
    logger:debug(out)

    if do_assert then
      error(out)
    end
  else
    return out
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

  validate { start_table = { "t", start } }

  for i = 2, l do
    validate { ["table_" .. i] = { "t", args[i] } }
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
  validate { start_table = { "t", start } }

  for i = 2, l do
    _merge(start, args[i])
  end

  return start
end

function apply(f, args)
  validate {
    f = { "f", f },
    params = { "t", args },
  }

  return f(unpack(args))
end

function items(t)
  validate { t = { "t", t } }

  local it = {}
  local i = 1
  for key, value in pairs(t) do
    it[i] = { key, value }
    i = i + 1
  end

  return it
end

function glob(d, expr, nosuf, alllinks)
  validate {
    directory = { "s", d },
    glob = { "s", expr },
    ["?no_suffix"] = { "b", nosuf },
    ["?all_links"] = { "b", alllinks },
  }
  nosuf = nosuf == nil and true or false

  return vim.fn.globpath(d, expr, nosuf, true, alllinks) or {}
end
