--- Buffer object creater. This does not YET cover all the neovim buffer API functions

if not buffer then class "Buffer" end

Buffer.ids = Buffer.ids or {}
Buffer._scratch_id = Buffer._scratch_id or 1

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

  if required < min then required = min end

  return required
end

function Buffer.vimsize()
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

function Buffer:float(opts)
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

  bufnr = self.bufnr
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
  local editor_size = Buffer.vimsize()
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
    if reverse then opts.col = current_width - opts.width end
  elseif dock then
    if opts.relative == "editor" then
      current_width = editor_size[1]
      current_height = editor_size[2]
    end

    opts.col = 0
    opts.row = opts.height - dock
    opts.height = from_percent(current_height, dock, 5)
    opts.width = current_width > 5 and current_width - 2 or current_width
    if reverse then opts.row = opts.height end
  end

  return vim.api.nvim_open_win(bufnr, focus, opts)
end

function Buffer.exists(self) return vim.fn.bufexists(self.bufnr) ~= 0 end

function Buffer.update(self) table.update(Buffer.ids, { self.bufnr }, self) end

function Buffer.getwidth(self)
  if not self:is_visible() then return end

  return vim.fn.winwidth(self:winnr())
end

function Buffer.getheight(self)
  if not self:is_visible() then return end

  return vim.fn.winheight(self:winnr())
end

--- Get buffer option
-- @tparam string opt Name of the option
-- @return any
function Buffer:getopt(opt)
  local _, out = pcall(vim.api.nvim_buf_get_option, self.bufnr, opt)

  if out ~= nil then return out end
end

--- Get buffer option
-- @tparam string var Name of the variable
-- @return any
function Buffer:getvar(var)
  local _, out = pcall(vim.api.nvim_buf_get_var, self.bufnr, var)

  if out ~= nil then return out end
end

function Buffer:setvar(k, v) vim.api.nvim_buf_set_var(self.bufnr, k, v) end

--- Set buffer variables
-- @tparam table vars Dictionary of var name and value
function Buffer:setvars(vars)
  table.teach(vars, function(k, v) self:setvar(k, v) end)

  return vars
end

--- Get buffer window option
-- @tparam string opt Name of the option
-- @return any
function Buffer:getwinopt(opt)
  if not self:is_visible() then return end

  local _, out = pcall(vim.api.nvim_win_get_option, self:winid(), opt)

  if out ~= nil then return out end
end

--- Get buffer window option
-- @tparam string var Name of the variable
-- @return any
function Buffer:getwinvar(var)
  if not self:is_visible() then return end

  local _, out = pcall(vim.api.nvim_win_get_var, self:winid(), var)

  if out then return out end
end

function Buffer:setwinvar(k, v)
  if not self:is_visible() then return end

  vim.api.nvim_win_set_var(self:winid(), k, v)
end

function Buffer:setwinvars(vars)
  if not self:is_visible() then return end

  table.teach(vars, function(k, v) self:setwinvar(k, v) end)

  return vars
end

function Buffer:setopt(k, v) vim.api.nvim_buf_set_option(self.bufnr, k, v) end

function Buffer:setopts(opts)
  for key, val in pairs(opts) do
    self:setopt(key, val)
  end
end

function Buffer.winnr(self)
  local winnr = vim.fn.bufwinnr(self.bufnr)
  if winnr == -1 then return end
  return winnr
end

function Buffer.winid(self)
  local winid = vim.fn.bufwinid(self.bufnr)
  if winid == -1 then return end
  return winid
end

function Buffer.focus(self)
  local winid = self:winid()
  if winid then
    vim.fn.win_gotoid(winid)
    return true
  end
end

function Buffer:setwinopt(k, v)
  if not self:is_visible() then return end

  vim.api.nvim_win_set_option(self:winid(), k, v)

  return v
end

function Buffer:setwinopts(opts)
  if not self:is_visible() then return end

  table.teach(opts, function(k, v) self:setwinopt(k, v) end)

  return opts
end

local function assert_exists(self)
  assert(self:exists(), "buffer does not exist: " .. self.bufnr)
end

--- Make a new buffer local mapping.
-- @param mode Mode to bind in
-- @param lhs Keys to bind callback to
-- @tparam function|string callback Callback to be bound to table.keys
-- @tparam[opt] table opts Additional vim.keymap.set options. You cannot set opts.pattern as it will be automatically set by this function
-- @return object Keybinding object
function Buffer:map(mode, lhs, callback, opts)
  assert_exists(self)

  opts = opts or {}
  opts.buffer = self.bufnr
  return Keybinding.map(mode, lhs, callback, opts)
end

--- Create a nonrecursive mapping
-- @see table.map
function Buffer:noremap(mode, lhs, callback, opts)
  assert_exists(self)

  opts = opts or {}
  if is_a.s(opts) then opts = { desc = opts } end
  opts.buffer = self.bufnr
  opts.noremap = true
  self:map(mode, lhs, callback, opts)
end

--- Split current window and focus this buffer
-- @param[opt='s'] split Direction to split in: 's' or 'v'
function Buffer:split(split, opts)
  assert_exists(self)

  opts = opts or {}
  split = split or "s"

  local required
  local reverse = opts.reverse
  local width = opts.resize or 0.3
  local height = opts.resize or 0.3
  local min = 0.1

  -- Use decimal table.values to use percentage changes
  if split == "s" then
    local current = vim.fn.winheight(0)
    required = from_percent(current, height, min)
    if not reverse then
      if opts.full then
        vim.cmd("botright split | b " .. self.bufnr)
      else
        vim.cmd("split | b " .. self.bufnr)
      end
    else
      if opts.full then
        vim.cmd(sprintf("botright split | wincmd j | b %d", self.bufnr))
      else
        vim.cmd(sprintf("split | wincmd j | b %d", self.bufnr))
      end
    end
    vim.cmd("resize " .. required)
  elseif split == "v" then
    local current = vim.fn.winwidth(0)
    required = from_percent(current, height or 0.5, min)
    if not reverse then
      if opts.full then
        vim.cmd("vert topleft split | b " .. self.bufnr)
      else
        vim.cmd("vsplit | b " .. self.bufnr)
      end
    else
      if opts.full then
        vim.cmd(sprintf("vert botright split | b %d", self.bufnr))
      else
        vim.cmd(sprintf("vsplit | wincmd l | b %d", self.bufnr))
      end
    end
    vim.cmd("vert resize " .. required)
  elseif split == "f" then
    self:float(opts)
  elseif split == "t" then
    vim.cmd(sprintf("tabnew | b %d", self.bufnr))
  end
end

function Buffer:splitright(opts)
  opts = opts or {}
  opts.reverse = nil
  return self:split("s", opts)
end

function Buffer:splitabove(opts)
  opts = opts or {}
  opts.reverse = true
  return self:split("s", opts)
end

function Buffer:splitbelow(opts)
  opts = opts or {}
  opts.reverse = nil
  return self:split("s", opts)
end

function Buffer:splitleft(opts)
  opts = opts or {}
  opts.reverse = true
  return self:split("v", opts)
end

--- Create a buffer local autocommand. The  pattern will be automatically set to '<buffer=%d>'
-- @see autocmd._init
function Buffer:hook(event, callback, opts)
  assert_exists(self)

  opts = opts or {}

  return Autocmd(
    event,
    table.merge(opts, {
      pattern = sprintf("<buffer=%d>", self.bufnr),
      callback = callback,
    })
  )
end

--- Hide current buffer if visible
function Buffer.hide(self)
  local winid = vim.fn.bufwinid(self.bufnr)
  if winid ~= -1 then
    local current_tab = vim.api.nvim_get_current_tabpage()
    local n_wins = #(vim.api.nvim_tabpage_list_wins(current_tab))
    if n_wins > 1 then vim.api.nvim_win_hide(winid) end
  end
end

---  Is buffer visible?
--  @return boolean
function Buffer.is_visible(self) return vim.fn.bufwinid(self.bufnr) ~= -1 end

--- Get buffer lines
-- @param startrow Starting row
-- @param tillrow Ending row
-- @return table
function Buffer:lines(startrow, tillrow)
  startrow = startrow or 0
  tillrow = tillrow or -1

  validate {
    start_row = { "n", startrow },
    end_row = { "n", tillrow },
  }

  return vim.api.nvim_buf_get_lines(self.bufnr, startrow, tillrow, false)
end

--- Get buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @param repl Replacement text
-- @return
function Buffer:text(start, till, repl)
  validate {
    start_cood = { "t", start },
    till_cood = { "t", till },
    replacement = { "t", repl },
    repl = { is { "s", "t" }, repl },
  }

  assert_exists(self)

  if is_a(repl) == "string" then repl = vim.split(repl, "[\n\r]") end

  local a, b = unpack(start)
  local m, n = unpack(till)

  return vim.api.nvim_buf_get_text(self.bufnr, a, m, b, n, repl)
end

function Buffer:bind(opts, ...)
  assert_exists(self)

  opts.buffer = self.bufnr

  return Keybinding.bind(opts, ...)
end

--- Set buffer lines
-- @param startrow Starting row
-- @param endrow Ending row
-- @param repl Replacement line[s]
function Buffer:setlines(startrow, endrow, repl)
  assert(startrow)
  assert(endrow)

  if is_a(repl, "string") then repl = vim.split(repl, "[\n\r]") end

  vim.api.nvim_buf_set_lines(self.bufnr, startrow, endrow, false, repl)
end

--- Set buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @tparam string|table repl Replacement text
function Buffer:set(start, till, repl)
  assert(is_a(start, "table"))
  assert(is_a(till, "table"))

  vim.api.nvim_buf_set_text(
    self.bufnr,
    start[1],
    till[1],
    start[2],
    till[2],
    repl
  )
end

--- Switch to this buffer
function Buffer.switch(self)
  assert_exists(self)

  vim.cmd("b " .. self.bufnr)
end

--- Load buffer
function Buffer.load(self)
  if vim.fn.bufloaded(self.bufnr) == 1 then
    return true
  else
    vim.fn.bufload(self.bufnr)
  end
end

--- Open scratch buffer in split
-- @param[opt='scratch_buffer'] name Name of the scratch buffer
-- @param split 's' (vertically) or 'v' (horizontally)
-- @return self
function Buffer.open_scratch(name, split)
  name = name or "scratch_buffer"
  local buf = Buffer(name, true)
  buf:split(split or "s")

  return buf
end

--- Call callback on buffer and return result
-- @param cb Function to call in this buffer
-- @return self
function Buffer:call(cb) return vim.api.nvim_buf_call(self.bufnr, cb) end

--- Get buffer-local keymap.
-- @see buffer_has_keymap
function Buffer:getmap(mode, lhs)
  return buffer_has_keymap(self.bufnr, mode, lhs)
end

--- Return visually highlighted table.range in this buffer
-- @see visualrange
function Buffer.range(self) return visualrange(self.bufnr) end

function Buffer.linecount(self) return vim.api.nvim_buf_line_count(self.bufnr) end

function Buffer.delete(self)
  local bufnr = self.bufnr

  if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
    self.ids[self.bufnr] = nil
  end
end

--- Return current linenumber
-- @return number
function Buffer.linenum(self)
  return self:call(function() return vim.fn.getpos(".")[2] end)
end

function Buffer.is_listed(self) return vim.fn.buflisted(self.bufnr) ~= 0 end

function Buffer.info(self) return vim.fn.getbufinfo(self.bufnr) end

function Buffer.wininfo(self)
  if not self:is_visible() then return end
  return vim.fn.getwininfo(self:winid())
end

function Buffer.string(self) return table.concat(self:lines(0, -1), "\n") end

function Buffer.getbuffer(self) return self:lines(0, -1) end

function Buffer:setbuffer(lines) return self:setlines(0, -1, lines) end

function Buffer.current_line(self)
  return self:call(function() return vim.fn.getline "." end)
end

function Buffer.lines_till_point(self)
  return self:call(function()
    local line = vim.fn.line "."
    return self:lines(0, line)
  end)
end

function Buffer.__tostring(self) return self:string() end

function Buffer:append(lines) return self:setlines(-1, -1, lines) end

function Buffer:prepend(lines) return self:setlines(0, 0, lines) end

function Buffer:maplines(f) return table.map(self:lines(0, -1), f) end

function Buffer:filter(f) return table.filter(self:lines(0, -1), f) end

function Buffer:match(pat)
  return table.filter(self:lines(0, -1), function(s) return s:match(pat) end)
end

function Buffer:readfile(fname)
  assert(path.exists(fname), "invalid path provided: " .. fname)

  local s = file.read(fname)
  self:setlines(0, -1, s)
end

function Buffer:insertfile(fname)
  assert(path.exists(fname), "invalid path provided: " .. fname)

  local s = file.read(fname)
  self:append(s)
end

function Buffer.save(self)
  self:call(function() vim.cmd "w! %:p" end)
end

function Buffer:shell(command)
  self:call(function() vim.cmd(":%! " .. command) end)

  return self:lines()
end

function Buffer:__add(s)
  self:append(s)

  return self
end

function Buffer.menu(desc, items, formatter, callback)
  validate {
    description = { is { "s", "t" }, desc },
    items = { is { "s", "t" }, items },
    callback = { "f", callback },
    ["?formatter"] = { "f", formatter },
  }

  if is_a.s(table.items) then table.items = vim.split(items, "\n") end

  if is_a.s(desc) then desc = vim.split(desc, "\n") end

  local b = Buffer()
  local desc_n = #desc
  local s = table.extend(desc, items)
  local lines = table.copy(s)

  if formatter then s = table.map(s, formatter) end

  local _callback = callback
  callback = function()
    local idx = vim.fn.line "."
    if idx <= desc_n then return end

    _callback(lines[idx])
  end

  b:setbuffer(s)

  b.o.modifiable = false

  b:hook("WinLeave", function() b:delete() end)

  b:bind({ noremap = true, event = "BufEnter" }, {
    "q",
    function() b:delete() end,
  }, { "<CR>", callback, "Run callback" })

  return b
end

--- Open buffer and run callback when table.keys are pressed
-- @param[opt=false] name Name of the scratch buffer. If skipped then create a unique id
-- @param text Text to display in the input buffer
-- @param cb Callback to run at keypress
-- @param opts Contains other options
-- @usage Buffer.input(name, text, cb, {
--   -- Split vertically or horizontally?
--   split = 's' or 'v'
--
--   -- Comments start with ? (default: #)
--   comment = '#' or string
--
--   -- When to run callback?
--   table.keys = 'gx' or string
-- })
-- @return Buffer
function Buffer.input(text, cb, opts)
  validate {
    text = { is { "t", "s" }, text },
    cb = { "f", cb },
    ["?opts"] = { "t", opts },
  }

  opts = opts or {}

  local split = opts.split or "s"
  local trigger_table = opts.keys or "gx"
  local comment = opts.comment or "#"

  if is_a(text, "string") then text = vim.split(text, "\n") end

  local buf = Buffer()
  buf:setlines(0, -1, text)

  buf:split(split, { reverse = opts.reverse, resize = opts.resize })

  buf:noremap("n", "gQ", function() b:delete() end, "Close buffer")

  buf:noremap("n", trigger_keys, function()
    local lines = buf:lines(0, -1)
    local sanitized = {}
    local idx = 1

    table.each(lines, function(s)
      if not s:match("^" .. comment) then
        sanitized[idx] = s
        idx = idx + 1
      end
    end)

    cb(sanitized)
  end, "Execute callback")

  buf:hook("WinLeave", function() buf:delete() end)
end

--- Constructor function returning a buffer object
-- @param name Name of the buffer
-- @param[opt] scratch Is a scratch buffer?
-- @return self
function Buffer:_init(name, scratch)
  local bufnr

  if not name then
    scratch = true
    name = "_scratch_buffer_" .. Buffer._scratch_id + 1
  end

  if is_a.n(name) then
    assert(
      vim.fn.bufexists(name) ~= 0,
      "invalid bufnr given: " .. tostring(name)
    )
    bufnr = name
    name = vim.fn.bufname(bufnr)
  else
    bufnr = vim.fn.bufadd(name)
  end

  if Buffer.ids[bufnr] then return Buffer.ids[bufnr] end

  self.bufnr = bufnr
  self.name = name
  self.fullname = vim.fn.bufname(bufnr)
  self.scratch = scratch
  self.wo = {}
  self.o = {}
  self.var = {}
  self.wvar = {}

  if scratch then
    Buffer._scratch_id = Buffer._scratch_id + 1
    self:setopts {
      modified = false,
      buflisted = false,
    }
    if self:getopt('buftype') ~= 'terminal' then
      self:setopt('buftype', 'nofile')
    else
      self.terminal = true
      self.scratch = nil
    end
  end

  setmetatable(self.var, {
    __index = function(_, k) return self:getvar(k) end,
    __newindex = function(_, k, v) return self:setvar(k, v) end,
  })

  setmetatable(self.o, {
    __index = function(_, k) return self:getopt(k) end,

    __newindex = function(_, k, v) return self:setopt(k, v) end,
  })

  setmetatable(self.wvar, {
    __index = function(_, k)
      if not self:is_visible() then return end

      return self:getwinvar(k)
    end,

    __newindex = function(_, k, v)
      if not self:is_visible() then return end

      return self:setwinvar(k, v)
    end,
  })

  setmetatable(self.wo, {
    __index = function(_, k)
      if not self:is_visible() then return end

      return self:getwinopt(k)
    end,

    __newindex = function(_, k, v)
      if not self:is_visible() then return end

      return self:setwinopt(k, v)
    end,
  })

  self:update()

  return self
end
