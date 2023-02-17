-- @classmod Keybinding Keybinding creater for neovim
class("Keybinding")
K = K or Keybinding

Keybinding.buffer = Keybinding.buffer or {}
Keybinding.id = Keybinding.id or {}
Keybinding.defaults = Keybinding.defaults or {}
local id = 1

local function update(self)
  V.update(Keybinding.id, self.id, self)

  if self.buffer then
    V.update(Keybinding.buffer, { self.buffer, self.id }, self)
  end

  if self.name then
    Keybinding.defaults[self.name] = self
  end

  return self
end

local function parse_opts(opts)
  opts = opts or {}
  local parsed = { au = {}, kbd = {}, misc = {} }

  V.teach(function(k, v)
    -- For autocommands
    if V.match(k, "pattern", "once", "nested", "group") then
      parsed.au[k] = v
    elseif V.match(k, "event", "name", "mode", "prefix", "leader", "localleader") then
      parsed.misc[k] = v
    else
      parsed.kbd[k] = v
    end
  end, opts)

  return parsed
end

---
-- Create a keybinding
-- @tparam string|table mode Mode
-- @tparam string lhs LHS
-- @tparam string|function cb Callback/RHS
-- @tparam table rest Rest of the optional arguments
-- @usage K(mode, lhs, cb, {
--   -- Any Autocmd-compatible params other than event
--   -- event and pattern when specified marks a local keybinding
--   event = string|table

--   -- Buffer local mapping. Pass a bufnr
--   buffer = number

--   -- Other keyboard args
--   mode = string|table = 'n'

--   -- Leader, localleader and prefix which will automatically modify LHS
--   localleader = boolean
--   leader = boolean
--
--   -- If provided then this object will be hashed in Keybinding.defaults
--   -- This WILL get overwritten and is NOT a preferred way to manipulate keybindings already set
--   name = string
--
--   -- Any other optional args required by vim.keymap.set
-- })
-- @see autocmd
-- @return object
function Keybinding:_init(mode, lhs, cb, rest)
  assert(mode, "No mode provided")
  assert(lhs, "No LHS provided")
  assert(cb, "No RHS provided")

  mode = mode or "n"
  if V.isstring(mode) then
    mode = vim.split(mode, "")
  end

  if V.isstring(rest) then
    rest = { desc = rest }
  end
  rest = rest or {}
  rest = parse_opts(rest)
  local au, kbd, misc = rest.au, rest.kbd, rest.misc
  local leader = misc.leader
  local localleader = misc.localleader
  local prefix = misc.prefix
  local buffer = kbd.buffer == true and vim.fn.buffer() or kbd.buffer
  mode = mode or misc.mode or "n"
  local event = misc.event
  local pattern = au.pattern
  local name = misc.name

  if leader then
    lhs = "<leader>" .. lhs
  elseif localleader then
    lhs = "<localleader>" .. lhs
  elseif prefix then
    lhs = prefix .. lhs
  end

  self.id = id
  id = id + 1
  if event and pattern then
    local callback = function()
      kbd.buffer = vim.fn.bufnr()
      vim.keymap.set(mode, lhs, cb, kbd)
      self.enabled = true
      update(self)
    end
    au.callback = callback
    self.autocmd = Autocmd(event, au)
  elseif buffer then
    vim.keymap.set(mode, lhs, cb, kbd)
    au.pattern = "<buffer=" .. buffer .. ">"
    local callback = function()
      self.enabled = true
      update(self)
    end
    au.callback = callback
    self.autocmd = Autocmd("BufEnter", au)
  else
    vim.keymap.set(mode, lhs, cb, kbd)
    self.enabled = true
    update(self)
  end

  self.desc = kbd.desc
  self.mode = mode
  self.lhs = lhs
  self.callback = cb
  self.name = name
  local o = {}

  V.merge(o, au)
  V.merge(o, misc)
  V.merge(o, kbd)

  self.opts = o

  return self
end

--- Disable keybinding
function Keybinding:disable()
  if not self.enabled then
    return
  end

  if self.autocmd then
    self.autocmd:delete()
    self.autocmd = nil
    if self.opts.buffer then
      for _, mode in ipairs(self.mode) do
        vim.api.nvim_buf_del_keymap(self.opts.buffer, mode, self.lhs)
      end
    end
    self.enabled = false
  else
    for _, mode in ipairs(self.mode) do
      vim.api.nvim_del_keymap(mode, self.lhs)
    end
    self.enabled = false
  end

  return self
end

--- Delete keybinding
function Keybinding:delete()
  if not self.enabled then
    return
  end

  self:disable()
  Keybinding.id[self.id] = nil

  if self.name then
    Keybinding.defaults[self.name] = nil
  end

  return self
end

---
-- Helper function for Keybinding() to set keybindings with default options
-- @tparam table opts Default options
-- @usage Keybinding.bind(
--   -- Valid default options:
--   -- leader, localleader, noremap, event, pattern, buffer, prefix, mode
--   opts,

--   -- If opts is present here then take precedence over defaults
--   -- Most generally, you will need this to other specifics as it will be merged with defaults
--   {lhs, cb, desc/opts},
--   ...
-- )
-- @return ?self Return object if only form was passed
function Keybinding.bind(opts, ...)
  opts = opts or {}
  local args = { ... }
  local bind = function(kbd)
    assert(V.isa(kbd, "table"))
    assert(#kbd >= 2)

    kbd[3] = kbd[3] or {}
    if V.isstring(kbd[3]) then
      kbd[3] = { desc = kbd[3] }
    end
    V.lmerge(kbd[3] or {}, opts)
    kbd[3].mode = kbd[3].mode or "n"
    local mode = kbd[3].mode

    return Keybinding(mode, unpack(kbd))
  end

  if #args == 1 then
    return bind(args[1])
  else
    V.each(bind, args)
  end
end

--- Simple classmethod that does the same thing as Keybinding()
function Keybinding.map(mode, lhs, cb, opts)
  return Keybinding(mode, lhs, cb, opts)
end

--- Same as map but sets noremap to true
function Keybinding.noremap(mode, lhs, cb, opts)
  opts = opts or {}
  opts.noremap = true

  return Keybinding(mode, lhs, cb, pts)
end

--- Replace current callback with a new one
-- @param cb Callback to replace with
function Keybinding:replace(cb)
  assert(cb)

  self:delete()

  return Keybinding(self.mode, self.lhs, cb, V.lmerge(opts or {}, self.opts))
end
