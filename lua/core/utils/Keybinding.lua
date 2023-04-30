--- Keybinding wrapper for vim.keymap.set which integrates with nvim autocommands API. Aliased as Keybinding
-- @classmod Keybinding
-- @alias K

Keybinding = class "Keybinding"
K = Keybinding

--- Contains instances hashed by name
user.kbd = user.kbd or {}

--- Contains instances hashed by unique integer
user.kbd.ID = user.kbd.ID or {}

local id = 1

function K._parse_opts(opts)
  opts = opts or {}
  local parsed = { au = {}, kbd = {}, misc = {} }

  dict.each(opts, function(k, v)
    -- For autocommands
    if str.match_any(k, "pattern", "once", "nested", "group") then
      parsed.au[k] = v
    elseif
      str.match_any(k, "event", "name", "mode", "prefix", "leader", "localleader", "cond")
    then
      parsed.misc[k] = v
    else
      parsed.kbd[k] = v
    end
  end)

  return parsed
end

--- Save instance in user.kbd and user.kbd.ID
-- @return self
function Keybinding:update()
  dict.update(user.kbd.ID, self.id, self)

  if self.name then
    user.kbd[self.name] = self
  end

  return self
end

--- Constructor
-- @param mode array[string]|string. If string is passed, it will be split, so that instead of passing a table, you can also pass 'nvo' for {'n', 'v', 'o'}. Any non-documented option is anything compatible with vim.keymap.set
-- @param lhs Keys to map to
-- @param cb string|callable
-- @param rest (Optional) If string then opts.desc will be automatically set. If table then rest of the options
-- @param rest.noremap Set as a non-recursive map (default: false)
-- @param rest.remap Set as a recursive map (default: true)
-- @param rest.leader Set as a leader map
-- @param rest.localeader Set as a localeader map
-- @param rest.prefix Prefix lhs. Cannot be used with rest.localleader or rest.leader
-- @param rest.event array[string]|string rest.pattern cannot be nil if this is used
-- @param rest.pattern array[string]|string rest.event cannot be nil if this is used
-- @param rest.name Unique name to reference this instance
-- @return object
function Keybinding:init(mode, lhs, cb, rest)
  validate {
    mode = { is { "string", "table" }, mode },
    lhs = { "string", lhs },
    cb = { is { "string", "callable" }, cb },
    ["?rest"] = { is {"table", 'string'}, rest },
  }

  rest = rest or {}
  mode = mode or rest.mode or "n"

  if is_a.string(mode) then
    mode = vim.split(mode, "")
  end

  if is_a.string(rest) then
    rest = { desc = rest }
  end

  rest = rest or {}
  rest = K._parse_opts(rest)
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
  user.kbd.ID[self.id] = nil

  if self.name then
    user.kbd[self.name] = nil
  end

  return self
end

--- Set multiple keybindings
-- @function Keybinding.bind
-- @param opts table Default options
-- @param ... Keybinding spec
-- @see Keybinding.init
function Keybinding.bind(opts, ...)
  local args = { ... }
  opts = opts or {}
  local bind = function(kbd)
    validate { kbd_spec = { "table", kbd } }
    assert(#kbd >= 2)

    local lhs, cb, o = unpack(kbd)

    validate {
      lhs = { "string", lhs },
      cb = { is { "string", "callable" }, cb },
      ['?o'] = { is { "table", "string" }, o },
    }

    o = o or {}
    if is_a.string(o) then o = { desc = o } end
    validate { kbd_opts = { "table", o } }

    for key, value in pairs(opts) do
      if not o[key] then
        o[key] = value
      end
    end

    local mode = o.mode or "n"
    kbd[3] = o

    return Keybinding(mode, unpack(kbd))
  end

  if #args == 1 then
    return bind(args[1])
  else
    array.each(args, bind)
  end
end

--- Replace current callback with a new one
-- @param cb Callback to replace with
-- @return self
function Keybinding:replace(cb)
  return utils.log_pcall(function()
    assert(cb)
    self:delete()
    return Keybinding.new(self.mode, self.lhs, cb, lmerge(opts or {}, self.opts))
  end)
end

--- Simple classmethod that does the same thing as Keybinding()
-- @static
-- @field Keybinding.map
-- @see Keybinding.init
-- @return self
function Keybinding.map(mode, lhs, cb, opts)
  return Keybinding.new(mode, lhs, cb, opts)
end

--- Same as .map but sets noremap to true
-- @static 
-- @field Keybinding.noremap
-- @return self
function Keybinding.noremap(mode, lhs, cb, opts)
  opts = opts or {}
  if is_a.string(opts) then
    opts = { desc = opts }
  end
  opts.noremap = true
  opts.remap = false

  return Keybinding.new(mode, lhs, cb, opts)
end

--- Unmap keybinding. ':help vim.keymap.del'
-- @static
-- @field Keybinding.unmap
-- @param modes string|array[string]
-- @param lhs Lhs to remove
-- @param opts optional options
function Keybinding.unmap(modes, lhs, opts)
  if is_a.string(modes) then modes = modes:split('') end
  vim.keymap.del(modes, lhs, opts)
end

return Keybinding
