---
-- Keybinding wrapper for vim.keymap.set which integrates with nvim autocommands API. Aliased as 'K'
class "Keybinding"

--- Alias for Keybinding
K = Keybinding

---
user.kbd = user.kbd or { ID = {} }

---
-- Contains maps indexed by name
K.defaults = {}

local id = 1

local function parse_opts(opts)
  opts = opts or {}
  local parsed = { au = {}, kbd = {}, misc = {} }

  dict.each(opts, function(k, v)
    -- For autocommands
    if string.match_any(k, "pattern", "once", "nested", "group") then
      parsed.au[k] = v
    elseif
      string.match_any(k, "event", "name", "mode", "prefix", "leader", "localleader", "cond")
    then
      parsed.misc[k] = v
    else
      parsed.kbd[k] = v
    end
  end)

  return parsed
end

---
-- Save object in K.ids and if name is passed, in K.defaults
-- @returns self
function K:update()
  dict.update(user.kbd.ID, self.id, self)

  if self.name then
    user.kbd[self.name] = self
  end

  return self
end

---
-- Create a keybinding
-- @tparam string|table mode If string is passed, it will be split, so that instead of passing a table, you can also pass 'nvo' for {'n', 'v', 'o'}. Any non-documented option is anything compatible with vim.keymap.set
-- @tparam string lhs Keys to map to
-- @tparam string|function cb Callback/RHS
-- @param rest (Optional) If string then opts.desc will be automatically set. If table then rest of the options
-- @param rest.noremap Set as a non-recursive map (default: false)
-- @param rest.remap Set as a recursive map (default: true)
-- @param rest.leader Set as a leader map
-- @param rest.localeader Set as a localeader map
-- @tparam string rest.prefix Prefix lhs. Cannot be used with rest.localleader or rest.leader
-- @tparam string|array.rest.event rest.pattern cannot be nil if this is used. Autocommand event(s) to bind to
-- @tparam string|array.rest.pattern rest.event cannot be nil if this is used. Autocommand pattern(s) to bind to
-- @see autocmd
-- @return object
function K:init(mode, lhs, cb, rest)
  validate {
    mode = { is { "string", "table" }, mode },
    lhs = { "string", lhs },
    cb = { is { "string", "callable" }, cb },
    ["?rest"] = { is {"table", 'string'}, rest },
  }

  rest = rest or {}
  mode = mode or rest.mode or "n"

  if is_a.s(mode) then
    mode = vim.split(mode, "")
  end

  if is_a.s(rest) then
    rest = { desc = rest }
  end

  rest = rest or {}
  rest = parse_opts(rest)
  local au, kbd, misc = rest.au, rest.kbd, rest.misc
  local leader = misc.leader
  local localleader = misc.localleader
  local prefix = misc.prefix
  local buffer = kbd.buffer == true and vim.fn.buffer() or kbd.buffer
  local event = misc.event
  local pattern = au.pattern
  local name = misc.name
  local cond = misc.cond
  kbd.noremap = kbd.remap and false or false
  kbd.remap = kbd.noremap and false or true
  local _cb = cb

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
      self:update()
    end
    au.callback = callback
    self.autocmd = Autocmd(event, au)
  elseif buffer then
    vim.keymap.set(mode, lhs, cb, kbd)
    au.pattern = "<buffer=" .. buffer .. ">"
    local callback = function()
      self.enabled = true
      self:update()
    end
    au.callback = callback
    self.autocmd = Autocmd("BufEnter", au)
  else
    vim.keymap.set(mode, lhs, cb, kbd)
    self.enabled = true
    self:update()
  end

  self.desc = kbd.desc
  self.mode = mode
  self.lhs = lhs
  self.callback = cb
  self.name = name
  local o = {}

  dict.merge(o, au)
  dict.merge(o, misc)
  dict.merge(o, kbd)

  self.opts = o

  return self
end

--- Disable keybinding
function K:disable()
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
function K:delete()
  if not self.enabled then
    return
  end

  self:disable()
  user.kbd.ID[self.id] = nil

  if self.name then
    user.kbd[self.name] = nil
  end

  return self
end

---
-- Helper function for Keybinding() to set keybindings with default options
-- @tparam table opts Default options
-- @return ?self Return object if only form was passed
function K.bind(opts, ...)
  local args = { ... }
  opts = opts or {}
  local bind = function(kbd)
    validate { kbd_spec = { "t", kbd } }
    assert(#kbd >= 2)

    local lhs, cb, o = unpack(kbd)

    validate {
      lhs = { "s", lhs },
      cb = { is { "s", "f" }, cb },
      ["?o"] = { is { "table", "string" }, o },
    }

    o = o or {}
    if is_a.s(o) then
      o = { desc = o }
    end
    validate { kbd_opts = { "table", o } }

    for key, value in pairs(opts) do
      if not o[key] then
        o[key] = value
      end
    end

    local mode = o.mode or "n"
    kbd[3] = o

    return K(mode, unpack(kbd))
  end

  if #args == 1 then
    return bind(args[1])
  else
    array.each(args, bind)
  end
end

--- Simple classmethod that does the same thing as Keybinding()
-- @see K:_init
function K.map(mode, lhs, cb, opts)
  return K.new(mode, lhs, cb, opts)
end

--- Same as K.map but sets noremap to true
function K.noremap(mode, lhs, cb, opts)
  opts = opts or {}
  if is_a.s(opts) then
    opts = { desc = opts }
  end
  opts.noremap = true
  opts.remap = false

  return K.new(mode, lhs, cb, opts)
end

--- Replace current callback with a new one
-- @param cb Callback to replace with
function K.replace(self, cb)
  return utils.log_pcall(function()
    assert(cb)
    self:delete()
    return K.new(self.mode, self.lhs, cb, lmerge(opts or {}, self.opts))
  end)
end

--- @see vim.keymap.del
function K.unmap(...)
  vim.keymap.del(...)
end
