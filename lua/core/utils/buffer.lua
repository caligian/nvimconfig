--- Common buffer operations. Many of them are simply aliases to their vim equivalents
-- requires: Autocmd, Keybinding
-- @module buffer
require "core.utils.win"
require "core.utils.au"
require "core.utils.kbd"

buffer = buffer or module "buffer"
buffer.float = module "buffer.float"
buffer.history = buffer.history or module "buffer.history"
buffer.recent = buffer.recent or ""

--- Add buffer by name or return existing buffer index. ':help bufadd()'
-- @function buffer.bufadd
-- @tparam number|string expr buffer index or name
-- @treturn number 0 on error, bufnr otherwise
buffer.bufadd = vim.fn.bufadd

function buffer.bufnr(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  bufnr = vim.fn.bufnr(bufnr)

  if bufnr == -1 then
    return false
  end

  return bufnr
end

buffer.current = buffer.bufnr

--- Send keystrokes to buffer. `:help feedkeys()`
-- @tparam number bufnr
-- @tparam string keys
-- @tparam ?string flags
-- @treturn false if invalid buffer is provided
function buffer.normal(bufnr, keys)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  buffer.call(bufnr, function()
    vim.cmd("normal! " .. keys)
  end)

  return true
end

--- Does buffer exists?
-- @tparam number bufnr buffer index
-- @treturn boolean success status
function buffer.exists(bufnr)
  return vim.fn.bufexists(bufnr) ~= 0
end

--- Unload and delete buffer
-- @tparam number bufnr buffer index
-- @treturn boolean success status
function buffer.wipeout(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  vim.api.nvim_buf_delete(bufnr, { force = true })
  return true
end

--- Unload and delete buffer
-- @function buffer.delete
-- @tparam number bufnr buffer index
-- @treturn boolean success status
buffer.delete = buffer.wipeout

function buffer.unload(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  vim.api.nvim_buf_delete(bufnr, { unload = true })
  return true
end

function buffer.get_keymap(bufnr, mode)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_buf_get_keymap(bufnr, mode)
end

function buffer.winnr(bufnr)
  bufnr = bufnr or buffer.bufnr()
  local winnr = vim.fn.bufwinnr(bufnr)
  if winnr == -1 then
    return false
  end

  return winnr
end

function buffer.winid(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    return false
  end

  return winid
end

--- Get buffer option
-- @tparam string opt Name of the option
-- @treturn any
function buffer.option(bufnr, opt)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  local _, out = pcall(vim.api.nvim_buf_get_option, bufnr, opt)
  if out ~= nil then
    return out
  end
end

--- Get buffer option
-- @tparam string var Name of the variable
-- @treturn any
function buffer.var(bufnr, var)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  local ok, out = pcall(vim.api.nvim_buf_get_var, bufnr, var)
  if ok then
    return out
  end
end

function buffer.set_var(bufnr, k, v)
  bufnr = bufnr or buffer.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  if isa.string(k) then
    vim.api.nvim_buf_set_var(bufnr, k, v)
  else
    dict.each(k, function(key, value)
      buffer.set_var(bufnr, key, value)
    end)
  end

  return true
end

--- Set buffer option
-- @tparam number bufnr
-- @tparam string k option name
-- @tparam any v value
function buffer.set_option(bufnr, k, v)
  bufnr = bufnr or buffer.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  if isa.string(k) then
    vim.api.nvim_buf_set_option(bufnr, k, v)
  else
    dict.each(k, function(key, value)
      buffer.set_option(bufnr, key, value)
    end)
  end

  return true
end

--- Make a new buffer local list.mapping.
-- @tparam number bufnr
-- @see Keybinding.map
-- @treturn Keybinding
function buffer.map(bufnr, mode, lhs, callback, opts)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  opts = opts or {}
  opts.buffer = bufnr

  return kbd.map(mode, lhs, callback, opts)
end

--- Make a new buffer local nonrecursive list.mapping.
-- @tparam number bufnr
-- @see Keybinding.noremap
-- @treturn Keybinding
function buffer.noremap(bufnr, mode, lhs, callback, opts)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  opts = opts or {}
  if isa.s(opts) then
    opts = { desc = opts }
  end
  opts.buffer = bufnr
  opts.noremap = true

  return buffer.map(bufnr, mode, lhs, callback, opts)
end

--- Create a buffer local autocommand. The  pattern will be automatically set to '<buffer=%d>'
-- @see au._init
function buffer.au(bufnr, event, callback, opts)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  opts = opts or {}

  return au.map(
    event,
    dict.merge(opts, {
      pattern = sprintf("<buffer=%d>", bufnr),
      callback = callback,
    })
  )
end

--- Hide current buffer if visible
---  Is buffer visible?
--  @return boolean
function buffer.isvisible(bufnr)
  return vim.fn.bufwinid(bufnr) ~= -1
end

--- Get buffer lines
-- @param startrow Starting row
-- @param tillrow Ending row
-- @return table
function buffer.lines(bufnr, startrow, tillrow)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  startrow = startrow or 0
  tillrow = tillrow or -1

  return vim.api.nvim_buf_get_lines(bufnr, startrow, tillrow, false)
end

--- Get buffer text
-- @tparam number start_row Starting row
-- @tparam number start_col Starting column
-- @tparam number end_row Ending row
-- @tparam number end_col Ending column
-- @tparam[opt] dict Options
-- @return
function buffer.text(bufnr, start_row, start_col, end_row, end_col, opts)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, opts or {})
end

--- Set buffer lines
-- @param startrow Starting row
-- @param endrow Ending row
-- @param repl Replacement line[s]
function buffer.set_lines(bufnr, startrow, endrow, repl)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  assert(startrow)
  assert(endrow)

  if isa(repl, "string") then
    repl = vim.split(repl, "[\n\r]")
  end

  vim.api.nvim_buf_set_lines(bufnr, startrow, endrow, false, repl)

  return true
end

--- Set buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @tparam string|table repl Replacement text
function buffer.set_text(bufnr, start, till, repl)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  vim.api.nvim_buf_set_text(self.bufnr, start[1], till[1], start[2], till[2], repl)

  return true
end

--- Switch to this buffer
function buffer.open(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  vim.cmd("b " .. bufnr)
  return true
end

--- Load buffer
function buffer.load(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  if vim.fn.bufloaded(bufnr) == 1 then
    return true
  else
    vim.fn.bufload(bufnr)
  end

  return true
end

--- Call callback on buffer and return result
-- @param cb Function to call in this buffer
-- @return self
function buffer.call(bufnr, cb)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_buf_call(bufnr, cb)
end

function buffer.linecount(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_buf_line_count(bufnr)
end

--- Return current linenumber
-- @return number
function buffer.linenum(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return buffer.call(bufnr, function()
    return vim.fn.getpos(".")[2]
  end)
end

function buffer.listed(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return vim.fn.buflisted(bufnr) ~= 0
end

function buffer.info(bufnr, all)
  local function _todict(lst)
    local new = {}
    list.each(lst, function(info)
      new[info.bufnr] = info
    end)

    return new, info
  end

  if isa.dict(bufnr) then
    return _todict(vim.fn.getbufinfo(bufnr))
  end

  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  if all then
    return _todict(vim.fn.getbufinfo(bufnr))
  else
    return _todict(vim.fn.getbufinfo(bufnr)[1])
  end
end

function buffer.list(criteria, opts)
  local found = buffer.info(criteria)
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
    out = list.map(out, buffer.name)
  end

  if remove_empty then
    out = list.filter(out, function(x)
      if isa.string(x) then
        return #x > 0
      else
        return #buffer.name(x) > 0
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

function buffer.string(bufnr)
  return table.concat(buffer.lines(bufnr, 0, -1), "\n")
end

function buffer.get_buffer(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return buffer.lines(bufnr, 0, -1)
end

function buffer.set_buffer(bufnr, lines)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return buffer.set_lines(bufnr, 0, -1, lines)
end

function buffer.current_line(bufnr)
  bufnr = bufnr or vim.fn.bufnr()

  if not buffer.exists(bufnr) then
    return
  end

  return buffer.pos(bufnr).row
end

function buffer.till_cursor(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  local winnr = buffer.winnr(winnr)
  if not winnr then
    return
  end

  return buffer.lines(bufnr, 0, win.row)
end

function buffer.append(bufnr, lines)
  return buffer.set_lines(bufnr, -1, -1, lines)
end

function buffer.prepend(bufnr, lines)
  return buffer.set_lines(bufnr, 0, 0, lines)
end

function buffer.map_lines(bufnr, f)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return list.map(buffer.lines(bufnr, 0, -1), f)
end

function buffer.filter(bufnr, f)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return list.filter(buffer.lines(bufnr, 0, -1), f)
end

function buffer.filter(bufnr, f)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return list.filter(buffer.lines(bufnr, 0, -1), f)
end

function buffer.match(bufnr, pat)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return list.filter(buffer.lines(bufnr, 0, -1), function(s)
    return s:match(pat)
  end)
end

function buffer.read_file(bufnr, fname)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  local s = file.read(fname)
  return buffer.set_lines(bufnr, -1, s)
end

function buffer.insert_file(bufnr, fname)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  local s = file.read(fname)
  return buffer.append(bufnr, s)
end

function buffer.save(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  buffer.call(bufnr, function()
    vim.cmd "w! %:p"
  end)
  return true
end

function buffer.shell(bufnr, command)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  buffer.call(bufnr, function()
    vim.cmd(":%! " .. command)
  end)

  return buffer.lines(bufnr)
end

function buffer.name(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_buf_get_name(bufnr or vim.fn.bufnr())
end

function buffer.create_empty(listed, scratch)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return vim.api.nvim_create_buf(listed, scratch)
end

function buffer.isempty(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  return #buffer.getbuffer(bufnr) == 0
end

function buffer.create(name)
  return (buffer.exists(name) and buffer.bufnr(name)) or buffer.bufadd(name)
end

function buffer.scratch(name, filetype)
  local bufnr
  if not name then
    bufnr = buffer.create_empty(listed, true)
  end

  local bufnr = bufnr or buffer.bufadd(name)
  if not buffer.exists(bufnr) then
    return
  end

  buffer.set_option(bufnr, { buflisted = false, buftype = "nofile", filetype = filetype })
  buffer.noremap(bufnr, "n", "q", ":hide<CR>", {})

  return bufnr
end

function buffer.input(text, cb, opts)
  opts = opts or {}

  local split = opts.split or "s"
  local trigger = opts.keys or "gx"
  local comment = opts.comment or "#"

  if isa(text, "string") then
    text = vim.split(text, "\n")
  end

  local buf = buffer.scratch()
  buffer.hook(buf, "WinLeave", function()
    buffer.wipeout(buf)
  end)
  buffer.set_lines(buf, 0, -1, text)
  buffer.split(buf, split, { reverse = opts.reverse, resize = opts.resize })
  buffer.noremap(buf, "n", "q", function()
    buffer.hide(buf)
  end, "Close buffer")
  buffer.noremap(buf, "n", trigger, function()
    local lines = buffer.lines(buffer.bufnr(), 0, -1)
    local sanitized = {}
    local idx = 1

    list.each(lines, function(s)
      if not s:match("^" .. comment) then
        sanitized[idx] = s
        idx = idx + 1
      end
    end)

    cb(sanitized)
  end, "Execute callback")

  return buf
end

--- Get treesitter node text at position
-- @tparam number bufnr
-- @tparam number row
-- @tparam number col
-- @treturn string
function buffer.get_node_text_at_pos(bufnr, row, col)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  local node = vim.treesitter.get_node { bufnr = bufnr, pos = { row, col } }
  if not node then
    return
  end

  return table.concat(buffer.text(bufnr, node:range()), "\n")
end

function buffer.windows(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  if not buffer.exists(bufnr) then
    return
  end

  local out = vim.fn.win_findbuf(buffer.bufnr())
  if #out == 0 then
    return
  else
    return out
  end
end

function buffer.toqflist(out)
  out = list.filter(out, function(x)
    return #x ~= 0
  end)
  out = list.map(out, function(x)
    return { bufnr = 0, text = x }
  end)

  vim.fn.setqflist(out)
  vim.cmd ":botright copen"
end

function buffer.split(bufnr, direction)
  direction = direction or "s"
  bufnr = bufnr or buffer.current()

  if not buffer.exists(bufnr) then
    return
  end

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
    local lines = buffer.lines(bufnr, 0, -1)
    buffer.toqflist(lines)
  end
end

function buffer.botright_vsplit(bufnr)
  return buffer.split(bufnr, "botright vsplit")
end

function buffer.topleft_vsplit(bufnr)
  return buffer.split(bufnr, "topleft vsplit")
end

function buffer.rightbelow_vsplit(bufnr)
  return buffer.split(bufnr, "belowright vsplit")
end

function buffer.leftabove_vsplit(bufnr)
  return buffer.split(bufnr, "aboveleft vsplit")
end

function buffer.belowright_vsplit(bufnr)
  return buffer.split(bufnr, "belowright vsplit")
end

function buffer.aboveleft_vsplit(bufnr)
  return buffer.split(bufnr, "aboveleft vsplit")
end

function buffer.botright(bufnr)
  return buffer.split(bufnr, "botright split")
end

function buffer.topleft(bufnr)
  return buffer.split(bufnr, "topleft split")
end

function buffer.rightbelow(bufnr)
  return buffer.split(bufnr, "belowright split")
end

function buffer.leftabove(bufnr)
  return buffer.split(bufnr, "aboveleft split")
end

function buffer.belowright(bufnr)
  return buffer.split(bufnr, "belowright split")
end

function buffer.aboveleft(bufnr)
  return buffer.split(bufnr, "aboveleft split")
end

function buffer.tabnew(bufnr)
  return buffer.split(bufnr, "t")
end

function buffer.vsplit(bufnr)
  return buffer.split(bufnr, "v")
end

--------------------------------------------------
local function from_percent(current, width, min)
  current = current or vim.fn.winwidth(0)
  width = width or 0.5

  assert(width ~= 0, "width cannot be 0")
  assert(width > 0, "width cannot be < 0")

  if width < 1 then
    required = math.floor(current * width)
  else
    return width
  end

  if min < 1 then
    min = math.floor(current * min)
  else
    min = math.floor(min)
  end

  if required < min then
    required = min
  end

  return required
end

local float = buffer.float
function float:__call(bufnr, opts)
  opts = opts or {}
  bufnr = bufnr or buffer.current()
  opts = opts or {}
  local dock = opts.dock
  local panel = opts.panel
  local center = opts.center
  local focus = opts.focus
  opts.dock = nil
  opts.panel = nil
  opts.center = nil
  opts.style = opts.style or "minimal"
  opts.border = opts.border or "single"
  local editor_size = win.vimsize()
  local current_width = win.width()
  local current_height = win.height()
  opts.width = opts.width or current_width
  opts.height = opts.height or current_height
  opts.relative = opts.relative or "editor"
  focus = focus == nil and true or focus
  local reverse = opts.reverse
  opts.reverse = nil

  if center then
    if opts.relative == "editor" then
      current_width = editor_size[1]
      current_height = editor_size[2]
    end

    local width, height = unpack(center)
    width = math.floor(from_percent(current_width, width, 10))
    height = math.floor(from_percent(current_height, height, 5))
    local col = (current_width - width) / 2
    local row = (current_height - height) / 2
    opts.width = width
    opts.height = height
    opts.col = math.floor(col)
    opts.row = math.floor(row)
  elseif panel then
    if opts.relative == "editor" then
      current_width = editor_size[1]
      current_height = editor_size[2]
    end

    opts.row = 0
    opts.col = 1
    opts.width = from_percent(current_width, panel, 5)
    opts.height = current_height

    if reverse then
      opts.col = current_width - opts.width
    end
  elseif dock then
    if opts.relative == "editor" then
      current_width = editor_size[1]
      current_height = editor_size[2]
    end

    opts.col = 0
    opts.row = opts.height - dock
    opts.height = from_percent(current_height, dock, 5)
    opts.width = current_width > 5 and current_width - 2 or current_width

    if reverse then
      opts.row = opts.height
    end
  end

  local winid = vim.api.nvim_open_win(bufnr, focus, opts)

  if winid == 0 then
    return false
  end

  return bufnr, winid
end

function float.panel(bufnr, size, opts)
  if not size then
    size = 30
  end

  local o = dict.merge({ panel = size }, opts or {})
  return float(bufnr, o)
end

function float.center(bufnr, size, opts)
  if not size then
    size = { 80, 80 }
  elseif isnumber(size) then
    local n = size
    size = { n, n }
  elseif #size == 1 then
    local n = size[1]
    size = { n, n }
  end

  return float(bufnr, dict.merge({ center = size }, opts))
end

function float.dock(bufnr, size, opts)
  size = size or 10
  return float(bufnr, dict.merge({ dock = size }, opts or {}))
end

function float.set_config(bufnr, config)
  config = config or {}
  local winnr = buffer.winnr(bufnr)
  local ok, msg = pcall(vim.api.nvim_win_set_config, win.nr2id(winnr), config)

  if not ok then
    return
  end

  return true
end

function float.get_config(bufnr)
  local winnr = buffer.winnr(bufnr)

  if not win.exists(winnr) then
    return
  end

  local ok, msg = pcall(vim.api.nvim_win_get_config, win.nr2id(winnr))
  if not ok then
    return
  end

  return ok
end

--------------------------------------------------

au.map("FileType", {
  pattern = "qf",
  callback = function()
    kbd.map("ni", "q", ":hide<CR>", { desc = "kill buffer", buffer = buffer.current() })
  end,
})

--------------------------------------------------
local hist = buffer.history

hist.ignore_filetypes = {
  TelescopePrompt = true,
  [""] = true,
}

hist.history = hist.history
  or setmetatable({}, {
    __index = function(self, key)
      return rawget(self, tostring(key))
    end,
  })

local history = hist.history

function hist.get_state()
  if #hist.history == 0 then
    return
  end

  return hist.history
end

function hist.print()
  for i = 1, #history do
    printf("%2d. %s", i, buffer.name(history[i]))
  end
end

function hist.prune()
  for i = 1, #history do
    local bufnr = history[i]
    local exists = buffer.exists(bufnr)

    if not buffer.exists(bufnr) then
      remove(history, i)
      history[tostring(bufnr)] = nil
    end
  end
end

function hist.push(bufnr)
  if not bufnr then
    return
  elseif history[#history] == buffer.current() then
    return
  elseif hist.ignore_filetypes[buffer.option(bufnr, "filetype")] then
    return
  end

  history[#history + 1] = bufnr
  history[tostring(bufnr)] = true

  return true
end

function hist.pop(n)
  local items = list.pop(history, n)
  items = tolist(items)

  if #items == 0 then
    return
  end

  list.each(items, function(bufnr)
    history[tostring(bufnr)] = nil
  end)

  return items
end

local function no_history()
  print "no buffer history left"
end

function hist.pop_open(n)
  hist.prune()

  local current = hist.pop(n)
  if not current then
    return no_history()
  else
    current = current[1]
  end

  if current == buffer.current() then
    current = hist.pop()
  else
    return buffer.open(current)
  end

  if not current then
    return no_history()
  end

  return buffer.open(current[1])
end

function hist.open()
  local current = hist.pop()

  if not current then
    return no_history()
  end

  current = current[1]
  if current == buffer.current() then
    current = hist.pop()
  else
    return buffer.open(current)
  end

  if not current then
    return no_history()
  end

  return buffer.open(current[1])
end

au.map("BufEnter", {
  pattern = "*",
  callback = function(opts)
    if hist.push(opts.buf) then
      buffer.recent = opts.buf
    end
  end,
})

function buffer.range_text(bufnr)
  bufnr = bufnr or buffer.bufnr()
  return win.range_text(buffer.winnr(bufnr))
end

function buffer.range(bufnr)
  bufnr = bufnr or buffer.bufnr()
  return win.range(buffer.winnr(bufnr))
end

function buffer.hide(bufnr)
  if buffer.isvisible(bufnr) then
    return win.hide(buffer.winnr(bufnr))
  end
end

function buffer.focus(bufnr)
  if buffer.isvisible(bufnr) then
    return win.focus(buffer.winnr(bufnr))
  end
end

buffer.add = buffer.bufadd

function buffer.filetype(bufnr)
  bufnr = buffer.bufnr(bufnr)
  return buffer.option(bufnr, "filetype")
end

return buffer
