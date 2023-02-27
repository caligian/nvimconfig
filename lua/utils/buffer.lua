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
    V.isstring(name)
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

  update(self)

  return self
end

--- Get buffer option
-- @tparam string opt Name of the option
-- @return any
function Buffer:getopt(opt)
  assert(self:exists())
  local _, out = pcall(vim.api.nvim_buf_get_option, self.bufnr, opt)

  if out then
    return out
  end
end

--- Get buffer option
-- @tparam string var Name of the variable
-- @return any
function Buffer:getvar(var)
  assert(self:exists())

  local _, out = pcall(vim.api.nvim_buf_get_var, self.bufnr, var)

  if out then
    return out
  end
end

--- Set buffer variables
-- @tparam table vars Dictionary of var name and value
function Buffer:setvar(vars)
  assert(self:exists())

  vars = vars or {}
  for key, value in pairs(vars) do
    vim.api.nvim_buf_set_var(self.bufnr, key, value)
  end
end

--- Set buffer options
-- @tparam table opts Dictionary of option name and value
function Buffer:setopt(opts)
  assert(self:exists())

  opts = opts or {}
  for key, value in pairs(opts) do
    vim.api.nvim_buf_set_option(self.bufnr, key, value)
  end
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

    V.each(function(s)
      if not s:match("^" .. comment) then
        sanitized[idx] = s
        idx = idx + 1
      end
    end, lines)

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

-- TODO: Add other buffer operations (if possible)
-- TODO: Add window operations
