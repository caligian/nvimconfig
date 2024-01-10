require "core.utils.kbd"

--- @class Buffer
--- @field buffer_index number
--- @field buffer_name string
--- @field mappings table<string,kbd>

-- if not Buffer then
Buffer = class "Buffer"
-- end

--- Is object a Buffer
--- @param self any
--- @return boolean
function Buffer.is_a(self)
  return is_table(self) and typeof(self) == "Buffer"
end

--- @param self Buffer|string|number
--- @return string?
function Buffer.to_name(self)
  assert_is_a(self, union(Buffer.is_a, "string", "number"))

  local bufnr
  if is_table(self) then
    bufnr = self.buffer_index --[[@as Buffer]]
  else
    bufnr = vim.fn.bufnr(self --[[@as number]])
  end

  local ok = vim.fn.bufnr(bufnr --[[@as number]]) ~= -1 and nvim.buf.get_name(bufnr)

  return defined(ok)
end

--- @param self Buffer|string|number
--- @return number?
function Buffer.to_bufnr(self)
  assert_is_a(self, union(Buffer.is_a, "string", "number", "Buffer"))
  local bufnr

  if is_table(self) then
    bufnr = self.buffer_index
  elseif is_string(self) then
    bufnr = vim.fn.bufnr(self --[[@as number]])
  else
    bufnr = self
  end

  local ok = vim.fn.bufnr(bufnr --[[@as number]]) ~= -1 and bufnr

  return defined(ok)
end

function Buffer.bufnr(bufnr)
  return bufnr and Buffer.to_bufnr(bufnr) or vim.fn.bufnr()
end

Buffer.current = Buffer.bufnr
Buffer.exists = Buffer.to_bufnr
Buffer.name = Buffer.to_name

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

function Buffer:init(bufnr_or_name, scratch, listed)
  params {
    bufid = {
      union("string", "number", "Buffer"),
      bufnr_or_name,
    },
    ["scratch?"] = { "boolean", scratch },
    ["listed?"] = { "boolean", listed },
  }

  if Buffer.is_a(bufnr_or_name) and nvim.buf.is_valid(bufnr_or_name.buffer_index) then
    return bufnr_or_name.buffer_index
  end

  if is_string(bufnr_or_name) then
    bufnr = vim.fn.bufadd(bufnr_or_name)
  else
    bufnr = Buffer.to_bufnr(bufnr_or_name)
  end

  self.buffer_index = bufnr
  self.buffer_name = vim.fn.bufname(bufnr)
  self.history = nil
  self.recent = nil
  self.mappings = {}

  if self.scratch then
    nvim.buf.set_keymap(bufnr, "n", "q", ":hide<CR>", { desc = "hide buffer", noremap = true })

    nvim.buf.set_option(bufnr, "bufhidden", "wipe")
  end

  nvim.buf.set_option(bufnr, "buflisted", listed and true or false)

  return self
end

--------------------------------------------------
local _Buffer = {}

function _Buffer.filetype(bufnr)
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

function _Buffer.range_text(bufnr)
  local range = _Buffer.range(bufnr)
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

function _Buffer.range(bufnr)
  return _Buffer.call(bufnr, function()
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

function _Buffer.focus(bufnr)
  if _Buffer.is_visible(bufnr) then
    return vim.fn.win_gotoid(_Buffer.winid(bufnr))
  end
end

function _Buffer.winnr(bufnr)
  local winnr = vim.fn.bufwinnr(bufnr)
  if winnr == -1 then
    return false
  end

  return winnr
end

function _Buffer.winid(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    return false
  end

  return winid
end

function _Buffer.unload(bufnr)
  if not Buffer.exists(bufnr) then
    return
  end

  vim.api.nvim_buf_delete(bufnr, { unload = true })
  return true
end

function _Buffer.get_keymap(bufnr, mode)
  if not Buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_buf_get_keymap(bufnr, mode)
end

function _Buffer.wipeout(bufnr)
  vim.api.nvim_buf_delete(bufnr, { force = true })
  return true
end

function _Buffer.normal(bufnr, keys)
  _Buffer.call(bufnr, function()
    vim.cmd("normal! " .. keys)
  end)

  return true
end

function _Buffer.call(bufnr, cb)
  return vim.api.nvim_buf_call(bufnr, cb)
end

function _Buffer.linecount(bufnr)
  return vim.api.nvim_buf_line_count(bufnr)
end

function _Buffer.linenum(bufnr)
  return _Buffer.call(bufnr, function()
    return vim.fn.getpos(".")[2]
  end)
end

function _Buffer.listed(bufnr)
  return vim.fn.buflisted(bufnr) ~= 0
end

function _Buffer.info(bufnr, all)
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

function _Buffer.list(bufnr, opts)
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

function _Buffer.is_visible(bufnr)
  return vim.fn.bufwinid(bufnr) ~= -1
end

function _Buffer.hide(bufnr)
  local winnr = vim.fn.bufwinnr(bufnr)
  if winnr == -1 then
    return
  end

  local winid = vim.fn.win_getid(winnr)
  if winid == 0 then
    return
  end

  vim.api.nvim_win_hide(winid)
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

function _Buffer.split(bufnr, direction)
  direction = direction or "s"

  local function cmd(s)
    s = s .. " | b " .. bufnr
    vim.cmd(s)
  end

  if strmatch(direction, "^v$", "^vsplit$") then
    cmd ":vsplit"
  elseif strmatch(direction, "^s$", "^split$") then
    cmd ":split"
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
    local lines = _Buffer.lines(bufnr, 0, -1)
    to_qflist(lines)
  end
end

function _Buffer.lines(bufnr, startrow, tillrow)
  startrow = startrow or 0
  tillrow = tillrow or -1

  return vim.api.nvim_buf_get_lines(bufnr, startrow, tillrow, false)
end

function _Buffer.text(bufnr, start_row, start_col, end_row, end_col, opts)
  return vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, opts or {})
end

--- Switch to this buffer
function _Buffer.open(bufnr)
  vim.cmd("b " .. bufnr)
  return true
end

--- Load buffer
function _Buffer.load(bufnr)
  if vim.fn.bufloaded(bufnr) == 1 then
    return true
  else
    vim.fn.bufload(bufnr)
  end

  return true
end

function _Buffer.botright_vsplit(bufnr)
  return _Buffer.split(bufnr, "botright vsplit")
end

function _Buffer.topleft_vsplit(bufnr)
  return _Buffer.split(bufnr, "topleft vsplit")
end

function _Buffer.rightbelow_vsplit(bufnr)
  return _Buffer.split(bufnr, "belowright vsplit")
end

function _Buffer.leftabove_vsplit(bufnr)
  return _Buffer.split(bufnr, "aboveleft vsplit")
end

function _Buffer.belowright_vsplit(bufnr)
  return _Buffer.split(bufnr, "belowright vsplit")
end

function _Buffer.aboveleft_vsplit(bufnr)
  return _Buffer.split(bufnr, "aboveleft vsplit")
end

function _Buffer.botright(bufnr)
  return _Buffer.split(bufnr, "botright split")
end

function _Buffer.is_pleft(bufnr)
  return _Buffer.split(bufnr, "topleft split")
end

function _Buffer.rightbelow(bufnr)
  return _Buffer.split(bufnr, "belowright split")
end

function _Buffer.leftabove(bufnr)
  return _Buffer.split(bufnr, "aboveleft split")
end

function _Buffer.belowright(bufnr)
  return _Buffer.split(bufnr, "belowright split")
end

function _Buffer.aboveleft(bufnr)
  return _Buffer.split(bufnr, "aboveleft split")
end

function _Buffer.tabnew(bufnr)
  return _Buffer.split(bufnr, "t")
end

function _Buffer.vsplit(bufnr)
  return _Buffer.split(bufnr, "v")
end

function _Buffer.map(bufnr, mode, lhs, callback, opts)
  opts = opts or {}

  if is_a.string(opts) then
    opts = { desc = opts }
  end

  opts.buffer = bufnr

  return _Buffer.map(bufnr, mode, lhs, callback, opts)
end

function _Buffer.noremap(bufnr, mode, lhs, callback, opts)
  opts = opts or {}

  if is_a.string(opts) then
    opts = { desc = opts }
  end

  opts.buffer = bufnr
  opts.noremap = true

  return _Buffer.map(bufnr, mode, lhs, callback, opts)
end

function _Buffer.autocmd(bufnr, event, callback, opts)
  opts = opts or {}

  return Autocmd.map(
    event,
    dict.merge(opts, { {
      pattern = sprintf("<buffer=%d>", bufnr),
      callback = callback,
    } })
  )
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

function _Buffer.get_options(bufnr, opts)
  assert_is_a(opts, "list")

  local out = {}
  list.each(opts, function(key)
    out[key] = nvim.buf.get_option(bufnr, key)
  end)

  return out
end

function _Buffer.set_options(bufnr, opts)
  dict.each(opts, function(key, value)
    nvim.buf.set_option(bufnr, key, value)
  end)

  return true
end

function _Buffer.string(bufnr)
  return table.concat(_Buffer.lines(bufnr, 0, -1), "\n")
end

function _Buffer.currentline(bufnr)
  return _Buffer.bufnrpos(bufnr).row
end

function _Buffer.till_cursor(bufnr)
  local winnr = _Buffer.winnr(bufnr)
  if not winnr then
    return
  end

  return _Buffer.lines(bufnr, 0, win.row)
end

function _Buffer.append(bufnr, lines)
  return _Buffer.set_lines(bufnr, -1, -1, false, lines)
end

function _Buffer.prepend(bufnr, lines)
  return _Buffer.set_lines(bufnr, 0, 0, false, lines)
end

function _Buffer.maplines(bufnr, f)
  return list.map(_Buffer.lines(bufnr, 0, -1), f)
end

function _Buffer.filter(bufnr, f)
  return list.filter(_Buffer.lines(bufnr, 0, -1), f)
end

function _Buffer.match(bufnr, pat)
  return list.filter(_Buffer.lines(bufnr, 0, -1), function(s)
    return s:match(pat)
  end)
end

function _Buffer.save(bufnr)
  _Buffer.call(bufnr, function()
    vim.cmd "w! %:p"
  end)

  return true
end

function _Buffer.shell(bufnr, command)
  _Buffer.call(bufnr, function()
    vim.cmd(":%! " .. command)
  end)

  return _Buffer.lines(bufnr, 0, -1)
end

function _Buffer.read_file(bufnr, fname)
  local s = Path.read(fname)
  return _Buffer.set_lines(bufnr, -1, s)
end

function _Buffer.insert_file(bufnr, fname)
  local s = Path.read(fname)
  return _Buffer.append(bufnr, s)
end

function _Buffer.is_empty(bufnr)
  return #_Buffer.lines(bufnr, 0, -1) == 0
end

function Buffer.scratch(name, filetype)
  local bufnr

  if not name then
    bufnr = nvim.create.buf(listed, true)
  end

  bufnr = bufnr or vim.fn.bufadd(name)
  if not Buffer.exists(bufnr) then
    return
  end

  _Buffer.set_options(bufnr, {
    buflisted = false,
    buftype = "nofile",
    filetype = filetype or "scratch",
    bufhidden = "wipe",
  })

  _Buffer.set_keymap(bufnr, "n", "q", ":hide<CR>", { noremap = true, desc = "hide buffer" })

  return bufnr
end

function _Buffer.pos(bufnr, expr)
  return _Buffer.call(bufnr, function()
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

function _Buffer.row(bufnr)
  local res = _Buffer.bufnrpos(bufnr)
  return res.row
end

function _Buffer.col(bufnr)
  local res = _Buffer.bufnrpos(bufnr)
  return res.col
end

function _Buffer.curpos(bufnr)
  local res = _Buffer.bufnrpos(bufnr)
  return { res.row, res.col }
end

function _Buffer.width(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    return
  end

  return nvim.win.call(winid, function()
    return vim.fn.winwidth(winid)
  end)
end

function _Buffer.height(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    return
  end

  return nvim.win.call(winid, function()
    return vim.fn.winheight(winid)
  end)
end

function _Buffer.size(bufnr)
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

function _Buffer.get_node(bufnr, row, col)
  local node = vim.treesitter.get_node {
    bufnr = bufnr,
    pos = { row, col },
  }

  if not node then
    return
  end

  return table.concat(_Buffer.text(bufnr, node:range()), "\n")
end

function _Buffer.set(bufnr, pos, lines)
  assert_is_a(pos, function(x)
    return is_list(x) and (#x == 2 or #x == 4) and list.is_a(x, "number"),
      "expected a list of numbers of length 2 or 4, got " .. dump(x)
  end)

  assert_is_a(lines, union("string", "table"))
  lines = is_string(lines) and split(lines, "\n") or lines

  if #pos == 2 then
    return _Buffer.set_lines(bufnr, pos[1], pos[2], false, lines)
  end

  return _Buffer.set_text(bufnr, pos[1], pos[2], pos[3], pos[4], lines)
end

Buffer.option = nvim.buf.get_option
Buffer.var = nvim.buf.get_var

dict.merge(_Buffer, { nvim.buf })
dict.merge(_Buffer, { require "core.utils.buffer.float" })
dict.each(_Buffer, function(key, value)
  local function f(bufnr, ...)
    bufnr = Buffer.to_bufnr(bufnr)
    if bufnr then
      return value(bufnr, ...)
    end

    return false, "expected valid bufnr, got" .. dump(bufnr)
  end

  Buffer[key] = f
end)
