--- Autocommand creater for this framework

class("Autocmd")
A = A or Autocmd

-- @field id Contains all the autocommands created
Autocmd.id = Autocmd.id or {}

-- @field Autocmd.defaults Autocommands set by default
Autocmd.defaults = Autocmd.defaults or {}

-- @field Autocmd.group Autocommands hashed by group id
Autocmd.group = Autocmd.group or {}

--- Create autocommand. The API is similar to vim.api.nvim_create_autocmd
-- @tparam string|table event Event[s] to bind to
-- @tparam table opts Options table required by vim.api.nvim_create_autocmd
-- @return self
function Autocmd:_init(event, opts)
  assert(V.istable(opts))
  assert(opts.callback)
  assert(opts.pattern)

  local augroup
  local group = V.copy(opts.group or {})
  local name = opts.name
  opts.name = nil
  if type(group) == "string" then
    augroup = vim.api.nvim_create_augroup(group)
  else
    group[1] = group[1] or "UserGlobal"
    group[2] = group[2] or {}
    augroup = vim.api.nvim_create_augroup(unpack(group))
    group = group[1]
  end

  local callback = opts.callback
  opts.callback = function()
    self.enabled = true
    if V.isstring(callback) then
      vim.cmd(callback)
    else
      callback()
    end
  end

  if opts.once then
    callback = opts.callback
    opts.callback = function()
      self.enabled = false
      callback()
    end
  end

  local id = V.autocmd(event, opts)
  self.id = id
  self.gid = augroup
  self.group = group
  self.event = event
  self.enabled = false
  self.opts = opts
  self.opts.name = name

  for key, value in pairs(opts) do
    self[key] = value
  end

  V.update(Autocmd.id, id, self)
  V.update(Autocmd.group, { augroup, id }, self)

  if name then
    Autocmd.defaults[name] = self
  end
  self.name = name

  return self
end

---
-- Disable autocmd
-- @return self
function Autocmd:disable()
  if not self.enabled then
    return
  end
  vim.api.nvim_del_autocmd(self.id)
  self.enabled = false

  return self
end

---
-- Delete autocmd and make it inaccessible
-- @return self
function Autocmd:delete()
  self:disable()

  if self.name then
    Autocmd.defaults[self.name] = nil
  end

  Autocmd.id[self.id] = nil
  Autocmd.group[self.group][self.id] = nil

  return self
end

--- Replace autocommand callback and remake the autocommands with new arguments
-- @param callback Replacement callback. Should be a string or a function
-- @return self
function Autocmd:replace(callback)
  self:delete()

  local opts = self.opts
  opts.callback = callback

  return Autocmd(self.event, opts)
end
