--- Buffer object creater. This does not YET cover all the neovim buffer API functions

-- @classmod Buffer
-- @submodule autocmd
class("Buffer")
B = B or Buffer

-- @field bufnr Buffer objects are hashed by bufnr
Buffer.ids = Buffer.ids or {}

-- @field scratch Scratch buffers
Buffer.scratch = Buffer.scratch or {}

-- Used for unique id generation
local input_buffer_n = 0

local function update(self)
  V.update(Buffer.ids, { self.bufnr }, self)

  if self.scratch then
    V.update(Buffer.scratch, { self.bufnr }, self)
  end
end

function Buffer:exists()
  return vim.fn.bufexists(self.bufnr) ~= 0
end

--- Constructor function returning a buffer object
-- @param name Name of the buffer
-- @param[opt] scratch Is a scratch buffer?
-- @return self
function Buffer:_init(name, scratch)
  if not name then
    scratch = true
  end

  local bufnr
  if not name and scratch then
    bufnr = vim.api.nvim_create_buf(false, true)
  elseif scratch then
    bufnr = vim.fn.bufnr(name, true)
  else
    assert(V.iss(name))
    bufnr = vim.fn.bufnr(name, true)
  end

  if Buffer.ids[bufnr] then
    return Buffer.ids[bufnr]
  end

  if scratch then
    vim.api.nvim_buf_set_option(bufnr, "buflisted", false)
    vim.api.nvim_buf_set_option(bufnr, "modified", false)
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  end

  self.bufnr = bufnr
  self.fullname = vim.fn.bufname(bufnr)
  self.scratch = scratch
  self.name = name
  self.wo = {}
  self.o = {}

  setmetatable(self.o, {
    __index = function(_, k)
      return self:getopt(k)
    end,

    __newindex = function(_, k, v)
      return self:setopt(k, v)
    end,
  })

  setmetatable(self.wo, {
    __index = function(_, k)
      if not self:is_visible() then
        return
      end

      return self:getwinopt(k)
    end,

    __newindex = function(_, k, v)
      if not self:is_visible() then
        return
      end

      return self:setwinopt(k, v)
    end,
  })

  update(self)

  return self
end

--- Get buffer option
-- @tparam string opt Name of the option
-- @return any
function Buffer:getopt(opt)
  assert(self:exists())

  local _, out = pcall(vim.api.nvim_buf_get_option, self.bufnr, opt)

  if out ~= nil then
    return out
  end
end

--- Get buffer option
-- @tparam string var Name of the variable
-- @return any
function Buffer:getvar(var)
  assert(self:exists())
  assert(V.iss(var))

  local _, out = pcall(vim.api.nvim_buf_get_var, self.bufnr, var)

  if out ~= nil then
    return out
  end
end

function Buffer:setvar(k, v)
  assert(self:exists())
  assert(V.iss(k))
  assert(v)

  vim.api.nvim_buf_set_var(self.bufnr, k, v)
end

--- Set buffer variables
-- @tparam table vars Dictionary of var name and value
function Buffer:setvars(vars)
  assert(self:exists())
  assert(V.ist(vars))

  V.teach(vars, V.partial(self.setvar, self))

  return vars
end

--- Get buffer window option
-- @tparam string opt Name of the option
-- @return any
function Buffer:getwinopt(opt)
  assert(self:exists())
  assert(V.iss(opt))

  if not self:is_visible() then
    return
  end

  local _, out = pcall(vim.api.nvim_win_get_option, self:winnr(), opt)

  if out ~= nil then
    return out
  end
end

--- Get buffer window option
-- @tparam string var Name of the variable
-- @return any
function Buffer:getwinvar(var)
  assert(self:exists())

  if not self:is_visible() then
    return
  end

  local _, out = pcall(vim.api.nvim_win_get_var, self:winnr(), var)

  if out then
    return out
  end
end

function Buffer:setwinvar(k, v)
  assert(self:exists())

  if not self:is_visible() then
    return
  end

  vim.api.nvim_win_set_var(self:winnr(), k, v)
end

function Buffer:setwinvars(vars)
  assert(self:exists())
  assert(V.ist(vars))

  if not self:is_visible() then
    return
  end

  V.teach(vars, V.partial(self.setwinvar, self))

  return vars
end

function Buffer:setopt(k, v)
  assert(self:exists())

  vim.api.nvim_buf_set_option(self.bufnr, k, v)
end

function Buffer:setopts(opts)
  assert(self:exists())

  V.teach(opts, V.partial(self.setopt, self))
end

function Buffer:winnr()
  assert(self:exists())

  local winnr = vim.fn.bufwinnr(self.bufnr)
  if winnr == -1 then
    return
  end
  return winnr
end

function Buffer:winid()
  assert(self:exists())

  local winid = vim.fn.bufwinid(self.bufnr)
  if winid == -1 then
    return
  end
  return winid
end

function Buffer:focus()
  assert(self:exists())

  local winid = self:winid()
  if winid then
    vim.fn.win_gotoid(winid)
    return true
  end
end

function Buffer:setwinopt(k, v)
  assert(self:exists())
  assert(V.iss(k))
  assert(v)

  if not self:is_visible() then
    return
  end

  vim.api.nvim_win_set_option(self:winnr(), k, v)

  return v
end

function Buffer:setwinopts(opts)
  assert(self:exists())
  assert(V.ist(opts))

  if not self:is_visible() then
    return
  end

  V.teach(opts, V.partial(self.setwinopt, self))

  return opts
end

--- Make a new buffer local mapping.
-- @param mode Mode to bind in
-- @param lhs Keys to bind callback to
-- @tparam function|string callback Callback to be bound to keys
-- @tparam[opt] table opts Additional vim.keymap.set options. You cannot set opts.pattern as it will be automatically set by this function
-- @return object Keybinding object
function Buffer:map(mode, lhs, callback, opts)
  assert(self:exists())

  opts = opts or {}
  opts.buffer = self.bufnr
  return Keybinding.map(mode, lhs, callback, opts)
end

--- Create a nonrecursive mapping
-- @see map
function Buffer:noremap(mode, lhs, callback, opts)
  assert(self:exists())

  opts = opts or {}
  opts.buffer = self.bufnr
  opts.noremap = true
  self:map(mode, lhs, callback, opts)
end

--- Split current window and focus this buffer
-- @param[opt='s'] split Direction to split in: 's' or 'v'
function Buffer:split(split)
  assert(self:exists())

  split = split or "s"

  if split == "s" then
    vim.cmd(V.sprintf("split | wincmd j | b %d", self.bufnr))
  elseif split == "v" then
    vim.cmd(V.sprintf("vsplit | wincmd l | b %d", self.bufnr))
  elseif split == "t" then
    vim.cmd(sprintf("tabnew | b %d", self.bufnr))
  end
end

--- Create a buffer local autocommand. The  pattern will be automatically set to '<buffer=%d>'
-- @see autocmd._init
function Buffer:hook(event, callback, opts)
  assert(self:exists())

  opts = opts or {}

  assert(event)
  assert(callback)

  return Autocmd(
    event,
    V.merge(opts, {
      pattern = sprintf("<buffer=%d>", self.bufnr),
      callback = callback,
    })
  )
end

--- Hide current buffer if visible
function Buffer:hide()
  assert(self:exists())

  local winid = vim.fn.bufwinid(self.bufnr)
  if winid ~= -1 then
    local current_tab = vim.api.nvim_get_current_tabpage()
    local n_wins = #(vim.api.nvim_tabpage_list_wins(current_tab))
    if n_wins > 1 then
      vim.fn.win_gotoid(winid)
      vim.cmd("hide")
    end
  end
end

---  Is buffer visible?
--  @return boolean
function Buffer:is_visible()
  assert(self:exists())
  return vim.fn.bufwinid(self.bufnr) ~= -1
end

--- Get buffer lines
-- @param startrow Starting row
-- @param tillrow Ending row
-- @return table
function Buffer:lines(startrow, tillrow)
  assert(self:exists())

  startrow = startrow or 0
  tillrow = tillrow or -1

  assert(V.isnumber(startrow))
  assert(V.isnumber(tillrow))

  return vim.api.nvim_buf_get_lines(self.bufnr, startrow, tillrow, false)
end

--- Get buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @param repl Replacement text
-- @return
function Buffer:text(start, till, repl)
  assert(self:exists())
  assert(V.isa(start, "table"))
  assert(V.isa(till, "table"))
  assert(repl)

  if V.isa(repl) == "string" then
    repl = vim.split(repl, "[\n\r]")
  end

  local a, b = unpack(start)
  local m, n = unpack(till)

  return vim.api.nvim_buf_get_text(self.bufnr, a, m, b, n, repl)
end

function Buffer:bind(opts, ...)
  assert(self:exists())

  V.asserttype(opts, "table")
  opts.buffer = self.bufnr

  return Keybinding.bind(opts, ...)
end

--- Set buffer lines
-- @param startrow Starting row
-- @param endrow Ending row
-- @param repl Replacement line[s]
function Buffer:setlines(startrow, endrow, repl)
  assert(self:exists())
  assert(startrow)
  assert(endrow)

  if V.isa(repl, "string") then
    repl = vim.split(repl, "[\n\r]")
  end

  vim.api.nvim_buf_set_lines(self.bufnr, startrow, endrow, false, repl)
end

--- Set buffer text
-- @tparam table start Should be table containing start row and col
-- @tparam table till Should be table containing end row and col
-- @tparam string|table repl Replacement text
function Buffer:set(start, till, repl)
  assert(self:exists())
  assert(V.isa(start, "table"))
  assert(V.isa(till, "table"))

  vim.api.nvim_buf_set_text(self.bufnr, start[1], till[1], start[2], till[2], repl)
end

--- Switch to this buffer
function Buffer:switch()
  assert(self:exists())

  vim.cmd("b " .. self.bufnr)
end

--- Load buffer
function Buffer:load()
  assert(self:exists())

  if vim.fn.bufloaded(self.bufnr) == 1 then
    return true
  else
    vim.fn.bufload(self.bufnr)
  end
end

--- Switch to scratch buffer
-- @param[opt] default If defined then use 'scratch_buffer' or display a menu to select the existing scratch buffer
function Buffer.switch_to_scratch(default)
  if default then
    local b = Buffer("scratch_buffer", true)
    b:switch()

    return b
  else
    vim.ui.select(V.map(vim.fn.bufname, V.keys(Buffer.scratch)), {
      prompt = "Switch to scratch buffer",
    }, function(b)
      vim.cmd("b " .. b)
    end)
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
function Buffer:call(cb)
  assert(self:exists())

  return vim.api.nvim_buf_call(self.bufnr, cb)
end

--- Open buffer and run callback when keys are pressed
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
--   keys = 'gx' or string
-- })
-- @return Buffer
function Buffer.input(name, text, cb, opts)
  opts = opts or {}
  local split = opts.split or "s"
  local trigger_keys = opts.keys or "gx"
  local comment = opts.comment or "#"

  if not name then
    name = "input_buffer_" .. input_buffer_n
    input_buffer_n = input_buffer_n + 1
  end

  if V.isa(text, "string") then
    text = vim.split(text, "\n")
  end

  local buf = Buffer(name, true)
  buf:setlines(0, -1, text)
  buf:split(split)

  buf:map("n", trigger_keys, function()
    local lines = buf:lines(0, -1)
    local sanitized = {}
    local idx = 1

    V.each(lines, function(s)
      if not s:match("^" .. comment) then
        sanitized[idx] = s
        idx = idx + 1
      end
    end)

    cb(sanitized)
  end, { noremap = true })
end

--- Get buffer-local keymap.
-- @see V.buffer_has_keymap
function Buffer:getmap(mode, lhs)
  assert(self:exists())

  return V.buffer_has_keymap(self.bufnr, mode, lhs)
end

--- Return visually highlighted range in this buffer
-- @see V.visualrange
function Buffer:range()
  assert(self:exists())

  return V.visualrange(self.bufnr)
end

function Buffer:linecount()
  assert(self:exists())

  return vim.api.nvim_buf_line_count(self.bufnr)
end

function Buffer:delete()
  if self:exists() then
    Buffer.ids[self.bufnr] = nil
    vim.cmd("bwipeout! " .. self.bufnr)
    return self
  end
end

--- Return current linenumber
-- @return number
function Buffer:linenum()
  assert(self:exists())

  return self:call(function()
    return vim.fn.getpos(".")[2]
  end)
end

function Buffer:is_listed()
  assert(self:exists())

  return vim.fn.buflisted(self.bufnr) ~= 0
end

function Buffer:info()
  assert(self:exists())

  return vim.fn.getbufinfo(self.bufnr)
end

function Buffer:wininfo()
  assert(self:exists())
  if not self:is_visible() then
    return
  end
  return vim.fn.getwininfo(self:winid())
end

function Buffer:string()
  return table.concat(self:lines(0, -1), "\n")
end

function Buffer:current_line()
  return self:call(function()
    return vim.fn.getline(".")
  end)
end

function Buffer:lines_till_point()
  return self:call(function()
    local line = vim.fn.line(".")
    return self:lines(0, line)
  end)
end

function Buffer:__tostring()
  return self:string()
end

function Buffer:append(lines)
  return self:setlines(-1, -1, lines)
end

function Buffer:prepend(lines)
  return self:setlines(0, 0, lines)
end

function Buffer:maplines(f)
  assert(self:exists())
  return V.map(self:lines(0, -1), f)
end

function Buffer:filter(f)
  assert(self:exists())
  return V.filter(self:lines(0, -1), f)
end

function Buffer:match(pat)
  assert(self:exists())
  assert(V.iss(pat))

  return V.filter(self:lines(0, -1), function(s)
    return s:match(pat)
  end)
end

function Buffer:readfile(fname)
  assert(path.exists(fname))

  local s = file.read(fname)
  self:setlines(0, -1, s)
end

function Buffer:insertfile(fname)
  assert(path.exists(fname))

  local s = file.read(fname)
  self:append(s)
end

function Buffer:save()
  self:call(function()
    vim.cmd("w! %:p")
  end)
end

function Buffer:shell(command)
  assert(V.iss(command))

  self:call(function()
    vim.cmd(":%! " .. command)
  end)

  return self:lines()
end

function Buffer:__add(s)
  self:append(s)

  return self
end

-- TODO: Add other buffer operations (if possible)
-- TODO: Add window operations
