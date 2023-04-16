require "utils.table"
require "utils.types"
require "utils.Autocmd"
require "utils.Keybinding"

buffer = {}
buffer.bufadd = vim.fn.bufadd

function buffer.exists(bufnr)
  return vim.fn.bufexists(bufnr) ~= 0
end

function buffer.wipeout(bufnr)
  if not buffer.exists(bufnr) then
    return false
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
  return true
end

buffer.delete = buffer.wipeout

function buffer.unload(bufnr)
  if not buffer.exists(bufnr) then
    return false
  end
  vim.api.nvim_buf_delete(bufnr, { unload = true })
  return true
end

function buffer.getmap(bufnr, mode)
  return vim.api.nvim_buf_get_keymap(bufnr, mode)
end

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

function buffer.vimsize()
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_call(scratch, function()
    vim.cmd "tabnew"
    local tabpage = vim.fn.tabpagenr()
    width = vim.fn.winwidth(0)
    height = vim.fn.winheight(0)
    vim.cmd("tabclose " .. tabpage)
  end)

  return { width, height }
end

function buffer.float(bufnr, opts)
  validate {
    win_options = {
      {
        __nonexistent = true,
        ["?center"] = "t",
        ["?panel"] = "n",
        ["?dock"] = "n",
      },
      opts or {},
    },
  }

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
  local editor_size = buffer.vimsize()
  local current_width = vim.fn.winwidth(0)
  local current_height = vim.fn.winheight(0)
  opts.width = opts.width or current_width
  opts.height = opts.height or current_height
  opts.relative = opts.relative or "editor"
  focus = focus == nil and true or focus

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

  return vim.api.nvim_open_win(bufnr, focus, opts)
end

function buffer.winnr(bufnr)
  local winnr = vim.fn.bufwinnr()
  if winnr == -1 then
    return false
  end
  return winnr
end

function buffer.winid(bufnr)
  local winid = vim.fn.bufwinnr()
  if winid == -1 then
    return false
  end
  return winid
end

function buffer.getwidth(bufnr)
  return vim.fn.winwidth(buffer.winnr(bufnr))
end

function buffer.getheight(bufnr)
  return vim.fn.winheight(buffer.winnr(bufnr))
end

--- Get buffer option
-- @tparam string opt Name of the option
-- @return any
function buffer.getopt(bufnr, opt)
  local _, out = pcall(vim.api.nvim_buf_get_option, bufnr, opt)
  if out ~= nil then
    return out
  end
end

--- Get buffer option
-- @tparam string var Name of the variable
-- @return any
function buffer.getvar(bufnr, var)
  local _, out = pcall(vim.api.nvim_buf_get_var, bufnr, var)
  if out ~= nil then
    return out
  end
end

function buffer.setvar(bufnr, k, v)
  vim.api.nvim_buf_set_var(bufnr, k, v)
end

--- Set buffer variables
-- @tparam table vars dictionary of var name and value
function buffer.setvars(bufnr, vars)
  dict.each(vars, function(k, v)
    buffer.setvar(bufnr, k, v)
  end)
  return vars
end

--- Get buffer window option
-- @tparam string opt Name of the option
-- @return any
function buffer.getwinopt(bufnr, opt)
  local _, out = pcall(vim.api.nvim_win_get_option, buffer.winid(bufnr), opt)
  if out ~= nil then
    return out
  end
end

--- Get buffer window option
-- @tparam string var Name of the variable
-- @return any
function buffer.getwinvar(bufnr, var)
  local _, out = pcall(vim.api.nvim_win_get_var, buffer.winid(bufnr), var)
  if out then
    return out
  end
end

function buffer.setwinvar(bufnr, k, v)
  vim.api.nvim_win_set_var(buffer.winid(bufnr), k, v)
end

function buffer.setwinvars(bufnr, vars)
  dict.each(vars, function(k, v)
    buffer.setwinvar(k, v)
  end)
  return vars
end

function buffer.setopt(bufnr, k, v)
  vim.api.nvim_buf_set_option(bufnr, k, v)
end

function buffer.setopts(bufnr, opts)
  for key, val in pairs(opts) do
    buffer.setopt(bufnr, key, val)
  end
end

function buffer.focus(bufnr)
  local winid = buffer.winid(bufnr)
  if winid then
    vim.fn.win_gotoid(winid)
    return true
  end
end

function buffer.setwinopt(bufnr, k, v)
  vim.api.nvim_win_set_option(buffer.winid(bufnr), k, v)
  return v
end

function buffer.setwinopts(bufnr, opts)
  dict.each(opts, function(k, v)
    buffer.setwinopt(bufnr, k, v)
  end)
  return opts
end

local function assert_exists(bufnr)
  assert(buffer.exists(bufnr), "buffer does not exist: " .. bufnr)
end

--- bufferake a new buffer local mapping.
-- @param mode bufferode to bind in
-- @param lhs Keys to bind callback to
-- @tparam function|string callback Callback to be bound to dict.keys
-- @tparam[opt] table opts Additional vim.keymap.set options. You cannot set opts.pattern as it will be automatically set by this function
-- @return object Keybinding object
function buffer.map(bufnr, mode, lhs, callback, opts)
  assert_exists(bufnr)
  opts = opts or {}
  opts.buffer = bufnr
  return Keybinding.map(mode, lhs, callback, opts)
end

--- Create a nonrecursive mapping
-- @see array.map
function buffer.noremap(bufnr, mode, lhs, callback, opts)
  assert_exists(bufnr)
  opts = opts or {}
  if is_a.s(opts) then
    opts = { desc = opts }
  end
  opts.buffer = bufnr
  opts.noremap = true
  buffer.map(bufnr, mode, lhs, callback, opts)
end

--- Split current window and focus this buffer
-- @param[opt='s'] split Direction to split in: 's' or 'v'
function buffer.split(bufnr, split, opts)
  assert_exists(bufnr)

  opts = opts or {}
  split = split or "s"

  local required
  local reverse = opts.reverse
  local width = opts.resize or 0.3
  local height = opts.resize or 0.3
  local min = 0.1

  -- Use decimal dict.values to use percentage changes
  if split == "s" then
    local current = vim.fn.winheight(0)
    required = from_percent(current, height, min)
    if not reverse then
      if opts.full then
        vim.cmd("botright split | b " .. bufnr)
      else
        vim.cmd("split | b " .. bufnr)
      end
    else
      if opts.full then
        vim.cmd(sprintf("botright split | wincmd j | b %d", bufnr))
      else
        vim.cmd(sprintf("split | wincmd j | b %d", bufnr))
      end
    end
    vim.cmd("resize " .. required)
  elseif split == "v" then
    local current = vim.fn.winwidth(0)
    required = from_percent(current, height or 0.5, min)
    if not reverse then
      if opts.full then
        vim.cmd("vert topleft split | b " .. bufnr)
      else
        vim.cmd("vsplit | b " .. bufnr)
      end
    else
      if opts.full then
        vim.cmd(sprintf("vert botright split | b %d", bufnr))
      else
        vim.cmd(sprintf("vsplit | wincmd l | b %d", bufnr))
      end
    end
    vim.cmd("vert resize " .. required)
  elseif split == "f" then
    buffer.float(bufnr, opts)
  elseif split == "t" then
    vim.cmd(sprintf("tabnew | b %d", bufnr))
  end
end

function buffer.splitright(bufnr, opts)
  opts = opts or {}
  opts.reverse = nil
  return buffer.split(bufnr, "s", opts)
end

function buffer.splitabove(bufnr, opts)
  opts = opts or {}
  opts.reverse = true
  return buffer.split(bufnr, "s", opts)
end

function buffer.splitbelow(bufnr, opts)
  opts = opts or {}
  opts.reverse = nil
  return buffer.split(bufnr, "s", opts)
end

function buffer.splitleft(bufnr, opts)
  opts = opts or {}
  opts.reverse = true
  return buffer.split(bufnr, "v", opts)
end

--- Create a buffer local autocommand. The  pattern will be automatically set to '<buffer=%d>'
-- @see autocmd._init
function buffer.hook(bufnr, event, callback, opts)
  assert_exists(bufnr)

  opts = opts or {}

  return Autocmd(
    event,
    dict.merge(opts, {
      pattern = sprintf("<buffer=%d>", bufnr),
      callback = callback,
    })
  )
end

--- Hide current buffer if visible
function buffer.hide(bufnr)
  local winid = vim.fn.bufwinid(bufnr)
  if winid ~= -1 then
    local current_tab = vim.api.nvim_get_current_tabpage()
    local n_wins = #(vim.api.nvim_tabpage_list_wins(current_tab))
    if n_wins > 1 then
      vim.api.nvim_win_hide(winid)
    else
      vim.cmd ":b#"
    end
  end
end

---  Is buffer visible?
--  @return boolean
function buffer.is_visible(bufnr)
  return vim.fn.bufwinid(bufnr) ~= -1
end

--- Get buffer lines
-- @param startrow Starting row
-- @param tillrow Ending row
-- @return table
function buffer.lines(bufnr, startrow, tillrow)
  startrow = startrow or 0
  tillrow = tillrow or -1

  validate {
    start_row = { "n", startrow },
    end_row = { "n", tillrow },
  }

  return vim.api.nvim_buf_get_lines(bufnr, startrow, tillrow, false)
end

--- Get buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @param repl Replacement text
-- @return
function buffer.text(bufnr, start, till, repl)
  validate {
    start_cood = { "t", start },
    till_cood = { "t", till },
    replacement = { "t", repl },
    repl = { is { "s", "t" }, repl },
  }

  assert_exists(self)

  if is_a(repl) == "string" then
    repl = vim.split(repl, "[\n\r]")
  end

  local a, b = unpack(start)
  local m, n = unpack(till)

  return vim.api.nvim_buf_get_text(bufnr, a, m, b, n, repl)
end

function buffer.bind(bufnr, opts, ...)
  opts.buffer = bufnr
  return Keybinding.bind(opts, ...)
end

--- Set buffer lines
-- @param startrow Starting row
-- @param endrow Ending row
-- @param repl Replacement line[s]
function buffer.setlines(bufnr, startrow, endrow, repl)
  assert(startrow)
  assert(endrow)

  if is_a(repl, "string") then
    repl = vim.split(repl, "[\n\r]")
  end

  vim.api.nvim_buf_set_lines(bufnr, startrow, endrow, false, repl)
end

--- Set buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @tparam string|table repl Replacement text
function buffer.set(bufnr, start, till, repl)
  assert(is_a(start, "table"))
  assert(is_a(till, "table"))

  vim.api.nvim_buf_set_text(self.bufnr, start[1], till[1], start[2], till[2], repl)
end

--- Switch to this buffer
function buffer.switch(bufnr)
  assert_exists(bufnr)
  vim.cmd("b " .. bufnr)
end

--- Load buffer
function buffer.load(bufnr)
  if vim.fn.bufloaded(bufnr) == 1 then
    return true
  else
    vim.fn.bufload(bufnr)
  end
end

--- Call callback on buffer and return result
-- @param cb Function to call in this buffer
-- @return self
function buffer.call(bufnr, cb)
  return vim.api.nvim_buf_call(bufnr, cb)
end

--- Return visually highlighted array.range in this buffer
-- @see visualrange
function buffer.range(bufnr)
  return buffer.call(bufnr or vim.fn.bufnr(), function()
    local _, csrow, cscol, _ = unpack(vim.fn.getpos "'<")
    local _, cerow, cecol, _ = unpack(vim.fn.getpos "'>")
    if csrow < cerow or (csrow == cerow and cscol <= cecol) then
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cecol, {})
    else
      return vim.api.nvim_buf_get_text(0, csrow - 1, cscol - 1, cerow - 1, cscol, {})
    end
  end)
end

function buffer.linecount(bufnr)
  return vim.api.nvim_buf_line_count(bufnr)
end

--- Return current linenumber
-- @return number
function buffer.linenum(bufnr)
  return buffer.call(bufnr, function()
    return vim.fn.getpos(".")[2]
  end)
end

function buffer.is_listed(bufnr)
  return vim.fn.buflisted(bufnr) ~= 0
end

function buffer.info(bufnr)
  return vim.fn.getbufinfo(bufnr)[1]
end

function buffer.wininfo(bufnr)
  if not buffer.is_visible(bufnr) then
    return
  end
  return vim.fn.getwininfo(buffer.winid(bufnr))
end

function buffer.string(bufnr)
  return table.concat(buffer.lines(bufnr, 0, -1), "\n")
end

function buffer.getbuffer(bufnr)
  return buffer.lines(bufnr, 0, -1)
end

function buffer.setbuffer(bufnr, lines)
  return buffer.setlines(bufnr, 0, -1, lines)
end

function buffer.current_line(bufnr)
  return buffer.call(bufnr, function()
    return vim.fn.getline "."
  end)
end

function buffer.lines_till_point(bufnr)
  return buffer.call(bufnr, function()
    local line = vim.fn.line "."
    return buffer.lines(bufnr, 0, line)
  end)
end

function buffer.append(bufnr, lines)
  return buffer.setlines(bufnr, -1, -1, lines)
end

function buffer.prepend(bufnr, lines)
  return buffer.setlines(bufnr, 0, 0, lines)
end

function buffer.maplines(bufnr, f)
  return array.map(buffer.lines(bufnr, 0, -1), f)
end

function buffer.filter(bufnr, f)
  return array.filter(buffer.lines(bufnr, 0, -1), f)
end

function buffer.match(bufnr, pat)
  return array.filter(buffer.lines(bufnr, 0, -1), function(s)
    return s:match(pat)
  end)
end

function buffer.readfile(bufnr, fname)
  local s = file.read(fname)
  buffer.setlines(bufnr, -1, s)
end

function buffer.insertfile(bufnr, fname)
  local s = file.read(fname)
  buffer.append(bufnr, s)
end

function buffer.save(bufnr)
  buffer.call(bufnr, function()
    vim.cmd "w! %:p"
  end)
end

function buffer.shell(bufnr, command)
  buffer.call(bufnr, function()
    vim.cmd(":%! " .. command)
  end)
  return buffer.lines(bufnr)
end

function buffer.bufnr(bufnr)
  bufnr = bufnr or vim.fn.bufnr()
  bufnr = vim.fn.bufnr(bufnr)
  if bufnr == -1 then
    return false
  end
  return bufnr
end

function buffer.name(bufnr)
  return vim.api.nvim_buf_get_name(bufnr)
end

function buffer.create_empty(listed, scratch)
  return vim.api.nvim_create_buf(listed, scratch)
end

function buffer.mkscratch(name, filetype)
  if not name then
    return buffer.create_empty(listed, true)
  end
  local bufnr = buffer.bufadd(name)
  if bufnr == 0 then
    return false
  end
  buffer.setopts(bufnr, { buflisted = false, buftype = "nofile", filetype = filetype })

  return bufnr
end

function buffer.open_scratch(name, split, opts)
  name = name or "__scratch_buffer__"
  local bufnr = buffer.mkscratch(name)
  buffer.split(bufnr, split, opts)
end

function buffer.menu(desc, items, formatter, callback)
  validate {
    description = { is { "s", "t" }, desc },
    items = { is { "s", "t" }, items },
    callback = { "f", callback },
    ["?formatter"] = { "f", formatter },
  }

  if is_a.s(dict.items) then
    dict.items = vim.split(items, "\n")
  end
  if is_a.s(desc) then
    desc = vim.split(desc, "\n")
  end
  local b = buffer.mkscratch()
  local desc_n = #desc
  local s = array.extend(desc, items)
  local lines = copy(s)
  if formatter then
    s = array.map(s, formatter)
  end
  local _callback = callback

  callback = function()
    local idx = vim.fn.line "."
    if idx <= desc_n then
      return
    end
    _callback(lines[idx])
  end

  buffer.setbuffer(b, s)
  buffer.setopt(b, "modifiable", false)
  buffer.hook(b, "WinLeave", function()
    buffer.delete(b)
  end)
  buffer.bind(b, { noremap = true, event = "BufEnter" }, {
    "q",
    function()
      buffer.hide(b)
    end,
  }, { "<CR>", callback, "Run callback" })

  return b
end

function buffer.input(text, cb, opts)
  validate {
    text = { is { "t", "s" }, text },
    cb = { "f", cb },
    ["?opts"] = { "t", opts },
  }

  opts = opts or {}

  local split = opts.split or "s"
  local trigger = opts.keys or "gx"
  local comment = opts.comment or "#"

  if is_a(text, "string") then
    text = vim.split(text, "\n")
  end

  local buf = buffer.mkscratch()
  buffer.hook(buf, "WinLeave", function()
    buffer.wipeout(buf)
  end)
  buffer.setlines(buf, 0, -1, text)
  buffer.split(buf, split, { reverse = opts.reverse, resize = opts.resize })
  buffer.noremap(buf, "n", "q", function()
    buffer.hide(buf)
  end, "Close buffer")
  buffer.noremap(buf, "n", trigger, function()
    local lines = buffer.lines(buffer.bufnr(), 0, -1)
    local sanitized = {}
    local idx = 1

    array.each(lines, function(s)
      if not s:match("^" .. comment) then
        sanitized[idx] = s
        idx = idx + 1
      end
    end)

    cb(sanitized)
  end, "Execute callback")
end
