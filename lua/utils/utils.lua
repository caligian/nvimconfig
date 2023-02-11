V.command = vim.api.nvim_create_user_command
V.autocmd = vim.api.nvim_create_autocmd
V.augroup = vim.api.nvim_create_augroup
V.bind = vim.keymap.set
V.stdpath = vim.fn.stdpath
V.flatten = vim.tbl_flatten
V.substr = string.sub
V.filter = vim.tbl_filter
V.deep_copy = vim.deepcopy
V.deepcopy = V.deep_copy
V.copy = vim.deepcopy
V.is_empty = vim.tbl_isempty
V.isempty = V.is_empty
V.is_list = vim.tbl_islist
V.islist = V.is_list
V.keys = vim.tbl_keys
V.values = vim.tbl_values
V.map = vim.tbl_map
V.trim = vim.trim
V.validate = vim.validate

function V.whereis(bin, regex)
  local out = vim.fn.system('whereis ' .. bin .. [[ | cut -d : -f 2- | sed -r "s/(^ *| *$)//mg"]])
  out = V.trim(out)
  out = vim.split(out, ' ')

  if V.isblank(out) then
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

function V.sprintf(s, fmt, ...)
  local args = { ... }

  for i = 1, #args do
    if type(args[i]) == 'table' then
      args[i] = vim.inspect(args[i])
    end
  end

  return string.format(s, fmt, unpack(args))
end

sprintf = V.sprintf

function V.extend(tbl, ...)
  local l = #tbl
  for i, t in ipairs({ ... }) do
    if type(t) == 'table' then
      for j, value in ipairs(t) do
        tbl[l + j] = value
      end
    else
      tbl[l + i] = t
    end
  end

  return tbl
end

function V.each(f, t)
  for _, value in ipairs(t) do
    f(value)
  end
end

function V.each_with_index(f, t)
  for idx, value in ipairs(t) do
    f(idx, value)
  end
end
V.ieach = V.each_with_index

function V.map_with_index(f, t)
  local out = {}
  for index, value in ipairs(t) do
    out[index] = f(index, value)
  end

  return out
end
V.imap = V.map_with_index

function V.inspect(...)
  local final_s = ''

  for _, obj in ipairs({ ... }) do
    if type(obj) == 'table' then
      obj = vim.inspect(obj)
    end
    final_s = final_s .. tostring(obj) .. '\n\n'
  end

  vim.api.nvim_echo({ { final_s } }, false, {})
end

inspect = V.inspect

function V.ensure_list(e, force)
  if force then
    return { e }
  elseif type(e) ~= 'table' then
    return { e }
  else
    return e
  end
end
V.tolist = V.ensure_list
V.ensurelist = V.ensure_list
V.to_list = V.tolist

function V.is_type(e, t)
  return type(e) == t
end
V.istype = V.is_type

function V.assert_type(e, t)
  local out = V.is_type(e)
  assert(out)

  return out
end

V.asserttype = V.assert_type

function V.append(t, ...)
  local idx = #t
  for i, value in ipairs({ ... }) do
    t[idx + i] = value
  end

  return t
end

function V.append_at_index(t, idx, ...)
  for _, value in ipairs({ ... }) do
    table.insert(t, idx, value)
  end

  return t
end
V.append_at = V.append_at_index
V.iappend = V.append_at_index
V.appendat = V.append_at

function V.shift(t, times)
  local l = #t
  for i = 1, times do
    if i > t then
      return t
    end
    table.remove(t, 1)
  end

  return t
end

function V.unshift(t, ...)
  for _, value in ipairs({ ... }) do
    table.insert(t, 1, value)
  end

  return t
end

-- For multiple patterns, OR matching will be used
function V.match(s, ...)
  for _, value in ipairs({ ... }) do
    local m = s:match(value)
    if m then
      return m
    end
  end
end

-- If varname in [varname] = var is prefixed with '!' then it will be overwritten
function V.global(vars)
  for var, value in pairs(vars) do
    if var:match('^!') then
      var = var:gsub('^!', '')
      _G[var] = value
    elseif _G[var] == nil then
      _G[var] = value
    end
    V.globals[var] = value
  end
end

function V.range(from, till, step)
  local index = from
  step = step or 1

  return function()
    index = index + step
    if index <= till then
      return index
    end
  end
end

function V.butlast(t)
  local new = {}

  for i = 1, #t - 1 do
    new[i] = t[i]
  end

  return new
end

function V.last(t, n)
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

function V.first(t, n)
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

function V.rest(t)
  local new = {}
  local len = #t
  local idx = 1

  for i = 2, len do
    new[idx] = t[i]
    idx = idx + 1
  end

  return new
end

function V.update(tbl, keys, value)
  keys = V.ensure_list(keys)
  local len_ks = #keys
  local t = tbl

  for idx, k in ipairs(keys) do
    local v = t[k]

    if idx == len_ks then
      t[k] = value
      return value, t, tbl
    elseif type(v) == 'table' then
      t = t[k]
    elseif v == nil then
      t[k] = {}
      t = t[k]
    else
      return
    end
  end
end

function V.rpartial(f, ...)
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

function V.partial(f, ...)
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

function V.get(tbl, ks, create_path)
  if type(ks) ~= 'table' then
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
    elseif type(v) == 'table' then
      t = t[k]
    elseif len_ks ~= index then
      return
    end
  end

  return v, t, tbl
end

function V.merge(a, b)
  local at = a
  local bt = b

  for key, value in pairs(bt) do
    local av = at[key]
    local bv = value

    if av == nil then
      at[key] = bv
    end

    if type(bv) == 'table' and type(av) == 'table' then
      V.merge(at[key], value)
    else
      at[key] = value
    end
  end

  return a
end

function V.merge_keepleft(a, b)
  local at = a
  local bt = b

  for key, value in pairs(bt) do
    local av = at[key]
    local bv = value

    if av == nil then
      at[key] = bv
    end

    if type(bv) == 'table' and type(av) == 'table' then
      V.merge_keepleft(at[key], value)
    elseif value ~= nil then
      at[key] = value
    end
  end

  return a
end

V.lmerge = V.merge_keepleft
V.mergekeepleft = V.merge_keepleft

function V.printf(...)
  print(V.sprintf(...))
end

function V.with_open(fname, mode, callback)
  local fh = io.open(fname, mode)
  local out = nil
  if fh then
    out = callback(fh)
    fh:close()
  end

  return out
end
V.open = V.with_open

function V.slice(t, from, till)
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

function V.index(t, item, test)
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

function V.buffer_has_keymap(bufnr, mode, lhs)
  bufnr = bufnr or 0
  local keymaps = vim.api.nvim_buf_get_keymap(bufnr, mode)
  lhs = lhs:gsub('<leader>', vim.g.mapleader)
  lhs = lhs:gsub('<localleader>', vim.g.maplocalleader)

  return V.index(keymaps, lhs, function(t, item)
    return t.lhs == item
  end)
end

function V.joinpath(...)
  return table.concat({ ... }, '/')
end

function V.basename(s)
  s = vim.split(s, '/')
  return s[#s]
end

function V.get_visual_range(bufnr)
  return vim.api.nvim_buf_call(bufnr or vim.fn.bufnr(), function()
    local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
    if csrow < cerow or (csrow == cerow and cscol <= cecol) then
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cecol, {})
    else
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cscol, {})
    end
  end)
end
V.getvisualrange = V.get_visual_range
V.visualrange = V.getvisualrange

function V.nvim_err(...)
  for _, s in ipairs({ ... }) do
    vim.api.nvim_err_writeln(s)
  end
end
V.nvimerr = V.nvim_err
V.err = V.nvimerr

function V.is_a(e, c)
  if type(c) == 'string' then
    return type(e) == c
  elseif type(e) == 'table' then
    if e.is_a and e:is_a(c) then
      return true
    else
      return 'table' == c
    end
  elseif c == nil then
    return e == nil
  end
end
V.isa = V.is_a
V.isstring = V.rpartial(V.is_a, 'string')
V.isuserdata = V.rpartial(V.is_a, 'userdata')
V.istable = V.rpartial(V.is_a, 'table')
V.isnumber = V.rpartial(V.is_a, 'string')
V.isnil = V.rpartial(V.is_a)
V.isfunction = V.rpartial(V.isa, 'function')
V.is_function = V.rpartial(V.isa, 'function')
V.is_string = V.rpartial(V.is_a, 'string')
V.is_userdata = V.rpartial(V.is_a, 'userdata')
V.is_table = V.rpartial(V.is_a, 'table')
V.is_number = V.rpartial(V.is_a, 'string')
V.is_nil = V.rpartial(V.is_a)

-- If multiple keys are supplied, the table is going to be assumed to be nested
function V.has_key(tbl, ...)
  return (V.get(tbl, { ... }))
end

V.haskey = V.has_key

function V.pcall(f, ...)
  local ok, out = pcall(f, ...)
  if ok then
    return {
      error = false,
      success = true,
      out = out,
    }
  else
    return {
      error = ok,
      success = false,
    }
  end
end

function V.makepath(t, ...)
  return V.get(t, { ... }, true)
end

function V.require(req, do_assert)
  local ok, out = pcall(require, req)

  if not ok then
    V.makepath(V, 'logs')
    V.append(V.logs, out)

    logger:warn(out)

    if do_assert then
      error(out)
    end
  else
    return out
  end
end

function V.is_blank(s)
  assert(V.isstring(s) or V.istable(s))

  if V.isstring(s) then
    return #s == 0
  elseif V.istable(s) then
    local i = 0
    for _, _ in pairs(s) do
      i = i + 1
    end
    return i == 0
  end
end
V.isblank = V.is_blank
