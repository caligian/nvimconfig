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
class_of = require('pl.class').class_of

function is_callable(t)
	local k = type(t)
	if k ~= 'table' and k ~= 'function' then
		return false
	elseif k == 'function' then
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

function is_class(e)
	if type(e) ~= 'table' then
		return e
	end

	local mt = getmetatable(e)
	if mt then
		if 
			mt._base and 
			mt._base.is_a then
			return true
		end
	end
	return false
end

local _tr = {
	s = 'string',
	t = 'table',
	u = 'userdata',
	n = 'number',
	f = 'callable',
	b = 'boolean',
	c = 'class',
	string = 'string',
	table = 'table',
	userdata = 'userdata',
	number = 'number',
	boolean = 'boolean',
	['function'] = 'callable',
	callable = 'callable',
}
-- This needs a rewrite
isa = setmetatable({ }, {
	__call = function (self, e, c)
		return self[c](e)
	end,

	-- Only works for native datatypes + callables
	__index = function(self, k)
		local fullform = _tr[k]
		if not fullform then
			error("Valid spec: '^[stunbf]$' or '^(string|table|userdata|function|callable|number|boolean)$'. spec provided: " .. k)
		elseif fullform then
			k = fullform
		end

		return function(e)
			local T = require 'pl.types'
			if k == 'callable' then
				return is_callable(e)
			elseif k == 'class' then
				return is_class(e)
			else
				return T.is_type(e, k)
			end
		end
	end
})

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
  assert(type(t) == "table", tostring(t) .. " is not a table")
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t)
  if not mt then
    return nil
  end

  return mt[k]
end

function mtset(t, k, v)
  assert(type(t) == "table", tostring(t) .. " is not a table")
  assert(k, "No attribute provided to query")

  local mt = getmetatable(t)
  if not mt then
    setmetatable(t, { [k] = v })
    mt = getmetatable(t)
  else
    mt[k] = v
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

-- Type checking

local function _is_class(t)
  local mt = getmetatable(t)
  if not mt then
    return false
  end

  if t.is_a then
    return true
  else
    return false
  end
end

local function _is_callable(f)
  if type(f) == "function" then
    return true
  elseif type(f) ~= "table" then
    return false
  end

  local mt = getmetatable(f) or {}
  if mt.__call then
    return true
  else
    return false
  end
end

--[[
Usage: 

validate {
  <display-var> = {
    <var>,
    <spec>,
  }
}

<var> string
Variable

<display-var> string
Varname to be used in assert

<spec> string|table
if <spec> == string then
  Either of [ntufbsc]. 
  If prefixed with ?, it will be considered optional
elseif <spec> == 'table' then
  Will be recursively matched against var. isa will be used.
  If __allow_nonexistent (default: false) is passed, keys not present in <spec-table> will not raise an error.
end

--]]
local function _is_pure_table(t)
  return isa.t(t) and not isa.c(t) and not isa.f(t)
end

local function _error_s(name, t)
  name = name or "<nonexistent>"
  return string.format("%s is not of type %s", name, t)
end

local function _validate(name, var, test)
  assert(name, "name not provided")
  assert(var, "var not provided")
  assert(test, "test spec not provided")

  if isa.f(test) then
    assert(test(var), string.format("callable failed %s", name))
  elseif not isa.t(test) then
    assert(isa(var, test), _error_s(name, _tr[test]))
  else
    assert(isa.t(var), _error_s(name, "table"))

    if _is_pure_table(var) and _is_pure_table(test) then
      return "pure_table"
    else
      assert(isa(var, test), _error_s(name, test))
    end
  end
end

local function _validate_table(t, spec)
  local allow_nonexistent = spec.__allow_nonexistent
  local id = spec.__table or tostring(t)
  spec.__table = nil
  spec.__allow_nonexistent = nil
  local not_supplied = {}

  for key, val in pairs(spec) do
    local name = key

    if not name:match "^%?" and not t[name] then
      print(name)
      table.insert(not_supplied, name)
    end
  end

  for key, val in pairs(spec) do
    spec[key:gsub("^%?", "")] = val
    spec[key] = nil
  end

  if #not_supplied > 0 then
    error(string.format("%s not supplied in %s", dump(not_supplied), id))
  end

  if not allow_nonexistent then
    for name, _ in pairs(t) do
      if not allowed[name] then
        error("unneeded key found: " .. name)
      end
    end
  end

  for name, var in pairs(t) do
    local required = spec[name]
    if required ~= nil then
      name = string.format("%s(%s)", id, name)
      if _validate(name, var, required) == "pure_table" then
        _validate_table(var, required)
      end
    end
  end
end

function validate(params)
  for name, param in pairs(params) do
    assert(isa.t(param) and #param >= 1, name .. " should be {spec, variable}")

    local spec, var = unpack(param)
    if _is_pure_table(var) and _is_pure_table(spec) then
      _validate_table(var, spec)
    else
      if name:match "^%?" then
        name = name:gsub("^%?", "")
        if var ~= nil then
          if isa.f(spec) then
            assert(spec(var), "callable failed " .. tostring(var))
          elseif isa.s(spec) then
            assert(isa(var, spec), name .. " is not of type " .. tostring(_tr[spec]))
          end
        end
      elseif isa.f(spec) then
        assert(spec(var), "callable failed " .. tostring(var))
      elseif isa.s(spec) then
        assert(isa(var, spec), name .. " is not of type " .. tostring(_tr[spec]))
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
  validate {
    format = { "string", fmt },
  }

  local args = { ... }

  for i = 1, #args do
    if isa.t(args[i]) then
      args[i] = dump(args[i])
    end
  end

  return string.format(fmt, unpack(args))
end

function extend(tbl, ...)
  validate { tbl = { "table", tbl } }

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

function teach(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  for key, value in pairs(t) do
    f(key, value)
  end
end

function map(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  local out = {}
  for key, value in ipairs(t) do
    out[key] = f(value)
  end

  return out
end

function tmap(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  local out = {}
  for key, value in pairs(t) do
    out[key] = f(key, value)
  end

  return out
end

function filter(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  local filtered = {}
  local i = 1

  for _, value in ipairs(t) do
    local out = f(value)
    if out then
      filtered[i] = out
      i = i + 1
    end
  end

  return filtered
end

function grep(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  local filtered = {}
  local i = 1

  for _, value in ipairs(t) do
    local out = f(value)
    if out then
      filtered[i] = value
      i = i + 1
    end
  end

  return filtered
end

function tgrep(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  local filtered = {}

  for key, value in pairs(t) do
    local out = f(value)
    if out then
      filtered[key] = value
    end
  end

  return filtered
end

function tfilter(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  local filtered = {}

  for key, value in pairs(t) do
    local out = f(key, value)
    if out then
      filtered[key] = out
    end
  end

  return filtered
end

function each(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  for _, value in ipairs(t) do
    f(value)
  end
end

function ieach(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  for idx, value in ipairs(t) do
    f(idx, value)
  end
end

function imap(t, f)
  validate {
    t = { "t", t },
    f = { "f", f },
  }

  local out = {}
  for index, value in ipairs(t) do
    out[index] = f(index, value)
  end

  return out
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

function tolist(e, force)
  if force then
    return { e }
  elseif type(e) ~= "table" then
    return { e }
  else
    return e
  end
end

function append(t, ...)
  validate { t = { "t", t } }

  local idx = #t
  for i, value in ipairs { ... } do
    t[idx + i] = value
  end

  return t
end

function iappend(t, idx, ...)
  validate {
    t = { "t", t },
    ["?index"] = { "n", idx },
  }

  for _, value in ipairs { ... } do
    table.insert(t, idx, value)
  end

  return t
end

function shift(t, times)
  validate {
    t = { "t", t },
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

function index(t, item, test)
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

  if isa.s(out) then
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
      elseif isa.t(a) and isa.t(b) then
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
      elseif isa.t(a) and isa.t(b) then
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
    validate { ["table_" .. i] = { "t", args[i] } }
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
