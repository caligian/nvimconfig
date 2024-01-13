require "core.utils.kbd"

--- @class Buffer
--- @field id number
--- @field buffer_name string
--- @field mappings table<string,kbd>

if not Buffer then
  Buffer = module()
end

--- Is object a Buffer
--- @param bufnr any
--- @return boolean
function Buffer.is_a(bufnr)
  return is_table(bufnr) and typeof(bufnr) == "Buffer"
end

--- @param bufnr Buffer|string|number
--- @return number?
function Buffer.bufnr(bufnr)
  if is_nil(bufnr) then
    return vim.fn.bufnr()
  end

  assert_is_a(bufnr, union(Buffer.is_a, "string", "number", "Buffer"))

  if is_table(bufnr) then
    bufnr = bufnr.id
  elseif is_string(bufnr) then
    bufnr = vim.fn.bufnr(bufnr --[[@as number]])
  end

  local ok = vim.fn.bufnr(bufnr --[[@as number]]) ~= -1 and bufnr

  return defined(ok)
end

Buffer.current = Buffer.bufnr
Buffer.exists = Buffer.bufnr

function Buffer.create(name)
  if not is_string(name) and not is_number(name) then
    return
  end

  if is_string(name) then
    return vim.fn.bufadd(name)
  elseif is_number(name) then
    return Buffer.exists(name) and name
  end
end

local function init(self, bufnr_or_name, scratch, listed)
  if is_nil(bufnr_or_name) then
    bufnr_or_name = vim.fn.bufnr()
  end

  if Buffer.is_a(bufnr_or_name) and nvim.buf.is_valid(bufnr_or_name.id) then
    return bufnr_or_name
  end

  local bufnr
  if is_string(bufnr_or_name) then
    bufnr = vim.fn.bufadd(bufnr_or_name)
  else
    bufnr = Buffer.bufnr(bufnr_or_name)
  end

  self.is_scratch = scratch
  self.id = bufnr
  self.name = vim.fn.bufname(bufnr)
  self.mappings = {}

  if self.scratch then
    nvim.buf.set_keymap(bufnr, "n", "q", ":hide<CR>", { desc = "hide buffer", noremap = true })
    nvim.buf.set_option(bufnr, "bufhidden", "wipe")
  end

  nvim.buf.set_option(bufnr, "buflisted", listed and true or false)

  return self
end

function Buffer:__call(bufnr_or_name, scratch, listed)
  if not Buffer.exists(bufnr) then
    return
  end

  local obj = class('Buffer')
  obj.init = init

  function obj:exists()
    if not self.id then
      return
    end

    return nvim.buf.is_valid(self.id)
  end

  function obj:scratch(listed)
    if self.is_scratch and self:exists() then
      return
    end

    if not obj:exists() then
      return
    end

    local bufnr = self.id

    if listed then
      nvim.buf.set_option(bufnr, 'buflisted', true)
    end

    nvim.buf.set_option(bufnr, 'buftype', 'nofile')

    vim.keymap.set({'n', 'i'}, 'q', ':hide<CR>', {desc = 'hide buffer', buffer = bufnr})

    obj.is_scratch = true

    return obj
  end

  function obj:create()
    if not self.name then
      return
    end

    return vim.fn.bufadd(self.name)
  end

  function obj:delete()
    if not self:exists() then
      return
    end

    nvim.buf.delete(self.id, {force = true})
    self.id = nil

    return true
  end

  obj.wipeout = obj.delete

  local ignore = {
    'current',
    '__call',
    'to_bufnr',
    'to_name',
    '__index',
    '__newindex',
  }

  local function should_ignore(key)
    return list.contains(ignore, key)
  end

  dict.each(Buffer, function (fun, method)
    if obj[fun] then
      return
    elseif should_ignore(fun) then
      return
    end

    obj[fun] = function (self, ...)
      if not self:exists() then
        return nil, 'invalid buffer ' .. dump(self.id)
      end

      return method(self.id, ...)
    end
  end)


  return init(obj, bufnr_or_name, scratch, listed)
end

function Buffer.call(bufnr, cb)
  return vim.api.nvim_buf_call(bufnr, cb)
end

function Buffer.filetype(bufnr)
  return nvim.buf.get_option(bufnr, "filetype")
end

local function range_text(buf, ...)
  local args = { ... }
  args = list.map(args, function(x)
    return x - 1
  end)
  args[#args + 1] = {}

  return vim.api.nvim_buf_get_text(buf, unpack(args))
end

function Buffer.range_text(bufnr)
  local range = Buffer.range(bufnr)
  if not range then
    return
  end

  ---@diagnostic disable-next-line: undefined-field, undefined-field
  local csrow, cerow = unpack(range.row)
  ---@diagnostic disable-next-line: undefined-field
  local cscol, cecol = unpack(range.col)
  local buf = Buffer.bufnr(winnr)

  return range_text(buf, csrow, cscol, cerow, cecol)
end

function Buffer.range(bufnr)
  return Buffer.call(bufnr, function()
    if vim.fn.mode() == "v" then
      vim.cmd "normal! "
    end

    local _, csrow, cscol, _ = unpack(vim.fn.getpos "'<")
    local _, cerow, cecol, _ = unpack(vim.fn.getpos "'>")

    if csrow > cerow or cscol > cecol then
      return
    end

    return { row = { csrow, cerow }, col = { cscol, cecol } }
  end)
end

function Buffer.focus(bufnr)
  if Buffer.is_visible(bufnr) then
    return vim.fn.win_gotoid(Buffer.winid(bufnr))
  end
end

function Buffer.winnr(bufnr)
  local winnr = vim.fn.bufwinnr(bufnr)
  if winnr == -1 then
    return false
  end

  return winnr
end

function Buffer.winid(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    return false
  end

  return winid
end

function Buffer.unload(bufnr)
  if not Buffer.exists(bufnr) then
    return
  end

  vim.api.nvim_buf_delete(bufnr, { unload = true })
  return true
end

function Buffer.get_keymap(bufnr, mode)
  if not Buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_buf_get_keymap(bufnr, mode)
end

function Buffer.wipeout(bufnr)
  vim.api.nvim_buf_delete(bufnr, { force = true })
  return true
end

function Buffer.normal(bufnr, keys)
  Buffer.call(bufnr, function()
    vim.cmd("normal! " .. keys)
  end)

  return true
end

function Buffer.linecount(bufnr)
  return vim.api.nvim_buf_line_count(bufnr)
end

function Buffer.linenum(bufnr)
  return Buffer.call(bufnr, function()
    return vim.fn.getpos(".")[2]
  end)
end

function Buffer.listed(bufnr)
  return vim.fn.buflisted(bufnr) ~= 0
end

function Buffer.info(bufnr, all)
  local function _todict(lst)
    local new = {}
    list.each(lst, function(info)
      new[info.bufnr] = info
    end)

    return new, info
  end

  if is_a.dict(bufnr) then
    return _todict(vim.fn.getbufinfo(bufnr))
  end

  bufnr = bufnr or vim.fn.bufnr()
  if not Buffer.exists(bufnr) then
    return
  end

  if all then
    return _todict(vim.fn.getbufinfo(bufnr))
  else
    return _todict(vim.fn.getbufinfo(bufnr)[1])
  end
end

function Buffer.list(bufnr, opts)
  params {
    bufnr = { "number", bufnr },
    ["opts?"] = { "table", opts },
  }

  local found = vim.fn.getbufinfo(bufnr)
  local out = keys(found)

  if #out == 0 then
    return
  end
  if not opts then
    return out
  end

  opts = opts or {}
  local usefilter = opts.filter
  local remove_empty = opts.remove_empty
  local apply = opts.apply
  local keep_dict = opts.dict
  local callback = opts.callback
  local name = opts.name

  if name then
    out = list.map(out, vim.fn.bufname)
  end

  if remove_empty then
    out = list.filter(out, function(x)
      if is_a.string(x) then
        return #x > 0
      else
        return #vim.fn.bufname(x) > 0
      end
    end)
  end

  if usefilter then
    out = list.filter(out, usefilter)
  end

  if apply then
    out = list.map(out, apply)
  end

  if callback then
    callback(out)
  end

  if keep_dict then
    local info = {}

    list.each(out, function(bufnr)
      info[bufnr] = found[bufnr]
    end)

    return info
  end

  return out
end

function Buffer.is_visible(bufnr)
  return vim.fn.bufwinid(bufnr) ~= -1
end

function Buffer.hide(bufnr)
  local winnr = vim.fn.bufwinnr(bufnr)
  if winnr == -1 then
    return
  end

  local winid = vim.fn.win_getid(winnr)
  if winid == 0 then
    return
  end

  local wins = nvim.tabpage.list_wins(0)
  if #wins == 1 then
    if #nvim.list.tabpages() > 1 then
      vim.cmd 'tabclose'
    else
      vim.cmd 'tabnew'
      vim.cmd 'tabprev | tabclose'
    end
  else
    vim.api.nvim_win_hide(winid)
  end

  return true
end

local function to_qflist(out)
  out = list.filter(out, function(x)
    return #x ~= 0
  end)

  out = list.map(out, function(x)
    return { bufnr = 0, text = x }
  end)

  vim.fn.setqflist(out)
  vim.cmd ":botright copen"
end

function Buffer.split(bufnr, direction)
  direction = direction or "s"

  local function cmd(s)
    s = s .. " | b " .. bufnr
    vim.cmd(s)
  end

  if strmatch(direction, "^v$", "^vsplit$") then
    cmd ":vsplit"
  elseif strmatch(direction, "^s$", "^split$") then
    cmd ":split"
  elseif is_template(direction) then
    direction = F(direction, {buf = bufnr})
    vim.cmd(direction)
  elseif direction:match "botright" then
    cmd(direction)
  elseif direction:match "topleft" then
    cmd(direction)
  elseif strmatch(direction, "aboveleft", "leftabove") then
    cmd(direction)
  elseif strmatch(direction, "belowright", "rightbelow") then
    cmd(direction)
  elseif direction == "tabnew" or direction == "t" or direction == "tab" then
    cmd ":tabnew"
  elseif string.match(direction, "qf") then
    local lines = Buffer.lines(bufnr, 0, -1)
    to_qflist(lines)
  else
    cmd(direction)
  end
end

function Buffer.lines(bufnr, startrow, tillrow)
  startrow = startrow or 0
  tillrow = tillrow or -1

  return vim.api.nvim_buf_get_lines(bufnr, startrow, tillrow, false)
end

function Buffer.text(bufnr, start_row, start_col, end_row, end_col, opts)
  return vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, opts or {})
end

--- Switch to this buffer
function Buffer.open(bufnr)
  vim.cmd("b " .. bufnr)
  return true
end

--- Load buffer
function Buffer.load(bufnr)
  if vim.fn.bufloaded(bufnr) == 1 then
    return true
  else
    vim.fn.bufload(bufnr)
  end

  return true
end

function Buffer.botright_vsplit(bufnr)
  return Buffer.split(bufnr, "botright vsplit")
end

function Buffer.topleft_vsplit(bufnr)
  return Buffer.split(bufnr, "topleft vsplit")
end

function Buffer.rightbelow_vsplit(bufnr)
  return Buffer.split(bufnr, "belowright vsplit")
end

function Buffer.leftabove_vsplit(bufnr)
  return Buffer.split(bufnr, "aboveleft vsplit")
end

function Buffer.belowright_vsplit(bufnr)
  return Buffer.split(bufnr, "belowright vsplit")
end

function Buffer.aboveleft_vsplit(bufnr)
  return Buffer.split(bufnr, "aboveleft vsplit")
end

function Buffer.botright(bufnr)
  return Buffer.split(bufnr, "botright split")
end

function Buffer.topleft(bufnr)
  return Buffer.split(bufnr, "topleft split")
end

function Buffer.rightbelow(bufnr)
  return Buffer.split(bufnr, "belowright split")
end

function Buffer.leftabove(bufnr)
  return Buffer.split(bufnr, "aboveleft split")
end

function Buffer.belowright(bufnr)
  return Buffer.split(bufnr, "belowright split")
end

function Buffer.aboveleft(bufnr)
  return Buffer.split(bufnr, "aboveleft split")
end

function Buffer.tabnew(bufnr)
  return Buffer.split(bufnr, "t")
end

function Buffer.vsplit(bufnr)
  return Buffer.split(bufnr, "v")
end

function Buffer.map(bufnr, mode, lhs, callback, opts)
  return Kbd.buffer.map(bufnr, mode, lhs, callback, opts)
end

function Buffer.noremap(bufnr, mode, lhs, callback, opts)
  return Kbd.buffer.noremap(bufnr, mode, lhs, callback, opts)
end

function Buffer.autocmd(bufnr, event, callback, opts)
  opts = opts or {}

  opts = dict.merge(opts, {{
    pattern = sprintf("<buffer=%d>", bufnr),
    callback = callback,
  }})

  return Autocmd(event, opts)
end

function Buffer.windows(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not Buffer.exists(bufnr) then
    return
  end

  local out = vim.fn.win_findbuf(Buffer.bufnr())
  if #out == 0 then
    return
  else
    return out
  end
end

function Buffer.get_options(bufnr, opts)
  assert_is_a(opts, "list")

  local out = {}
  list.each(opts, function(key)
    out[key] = nvim.buf.get_option(bufnr, key)
  end)

  return out
end

function Buffer.set_options(bufnr, opts)
  opts = opts or {}

  dict.each(opts, function(key, value)
    nvim.buf.set_option(bufnr, key, value)
  end)

  return true
end

function Buffer.string(bufnr)
  return table.concat(Buffer.lines(bufnr, 0, -1), "\n")
end

function Buffer.current_line(bufnr)
  local row = Buffer.pos(bufnr).row 
  return Buffer.get_lines(bufnr, row-1, row, false)[1]
end

function Buffer.till_cursor(bufnr)
  local winnr = Buffer.winnr(bufnr)
  if not winnr then
    return
  end

  return Buffer.lines(bufnr, 0, win.row)
end

function Buffer.append(bufnr, lines)
  return Buffer.set_lines(bufnr, -1, -1, false, lines)
end

function Buffer.prepend(bufnr, lines)
  return Buffer.set_lines(bufnr, 0, 0, false, lines)
end

function Buffer.map_lines(bufnr, f)
  return list.map(Buffer.lines(bufnr, 0, -1), f)
end

function Buffer.filter(bufnr, f)
  return list.filter(Buffer.lines(bufnr, 0, -1), f)
end

function Buffer.match(bufnr, pat)
  return list.filter(Buffer.lines(bufnr, 0, -1), function(s)
    return s:match(pat)
  end)
end

function Buffer.save(bufnr)
  Buffer.call(bufnr, function()
    vim.cmd "w! %:p"
  end)

  return true
end

function Buffer.shell(bufnr, command)
  Buffer.call(bufnr, function()
    vim.cmd(":%! " .. command)
  end)

  return Buffer.lines(bufnr, 0, -1)
end

function Buffer.read_file(bufnr, fname)
  local s = Path.read(fname)
  return Buffer.set_lines(bufnr, -1, s)
end

function Buffer.insert_file(bufnr, fname)
  local s = Path.read(fname)
  return Buffer.append(bufnr, s)
end

function Buffer.is_empty(bufnr)
  return #Buffer.lines(bufnr, 0, -1) == 0
end

function Buffer.scratch(name, listed)
  local bufnr

  if not name then
    bufnr = nvim.create.buf(listed, true)
  end

  bufnr = bufnr or vim.fn.bufadd(name)
  if not Buffer.exists(bufnr) then
    return
  end

  Buffer.set_options(bufnr, {
    buflisted = false,
    buftype = "nofile",
    filetype ="scratch",
    bufhidden = "wipe",
  })

  Buffer.set_keymap(bufnr, "n", "q", ":hide<CR>", { noremap = true, desc = "hide buffer" })

  return bufnr
end

function Buffer.pos(bufnr, expr)
  return Buffer.call(bufnr, function()
    local _, lnum, col, off = unpack(vim.fn.getpos(expr or "."))

    local out = {
      row = lnum,
      col = col,
      offset = off,
      bufnr = bufnr,
    }

    return out
  end)
end

function Buffer.row(bufnr)
  local res = Buffer.pos(bufnr)
  return res.row
end

function Buffer.col(bufnr)
  local res = Buffer.pos(bufnr)
  return res.col
end

function Buffer.curpos(bufnr)
  local res = Buffer.pos(bufnr)
  return { res.row, res.col }
end

function Buffer.width(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    return
  end

  return nvim.win.call(winid, function()
    return vim.fn.winwidth(winid)
  end)
end

function Buffer.height(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    return
  end

  return nvim.win.call(winid, function()
    return vim.fn.winheight(winid)
  end)
end

function Buffer.size(bufnr)
  local winid = vim.fn.bufwinid(bufnr)

  if winid == -1 then
    return
  end

  return nvim.win.call(winid, function()
    return {
      vim.fn.winwidth(winid),
      vim.fn.winheight(winid),
    }
  end)
end

function Buffer.get_node(bufnr, row, col)
  local node = vim.treesitter.get_node {
    bufnr = bufnr,
    pos = { row, col },
  }

  if not node then
    return
  end

  return table.concat(Buffer.text(bufnr, node:range()), "\n")
end

function Buffer.set(bufnr, pos, lines)
  assert_is_a(pos, function(x)
    return is_list(x) and (#x == 2 or #x == 4) and list.is_a(x, "number"),
      "expected a list of numbers of length 2 or 4, got " .. dump(x)
  end)

  assert_is_a(lines, union("string", "table"))
  lines = is_string(lines) and split(lines, "\n") or lines

  if #pos == 2 then
    return Buffer.set_lines(bufnr, pos[1], pos[2], false, lines)
  end

  return Buffer.set_text(bufnr, pos[1], pos[2], pos[3], pos[4], lines)
end

function Buffer.get_line(bufnr, row)
  if not Buffer.exists(bufnr) then
    return
  end

  local row = row or Buffer.row(bufnr, row) - 1

  if row then
    return Buffer.get_lines(bufnr, row, row+1, false)[1]
  end
end

Buffer.option = nvim.buf.get_option
Buffer.var = nvim.buf.get_var

dict.merge(Buffer, { nvim.buf })
dict.merge(Buffer, { require "core.utils.buffer.float" })

function is_buffer(self)
  return typeof(self) == 'Buffer'
end
