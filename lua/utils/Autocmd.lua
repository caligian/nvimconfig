---
-- @classmod Autocommand wrapper for vim.api.nvim_create_autocmd.
class "Autocmd"

---
-- @field A Alias for Autocommand
A = Autocmd
user.autocmd = user.autocmd or { ID = {}, GROUP = {}, BUFFER = {} }

function Autocmd:init(event, opts)
  validate {
    event = { is { "s", "t" }, event },
    options = {
      {
        callback = is { "f", "s" },
        pattern = is { "s", "t" },
      },
      opts,
    },
  }

  local augroup
  local group = copy(opts.group or {})
  local name = opts.name
  opts.name = nil
  if type(group) == "string" then
    augroup = vim.api.nvim_create_augroup(group, {})
  else
    group[1] = group[1] or "UserGlobal"
    group[2] = group[2] or {}
    augroup = vim.api.nvim_create_augroup(unpack(group))
    group = group[1]
  end

  local callback = opts.callback
  opts.callback = function(...)
    if opts.once then
      if is_a.s(callback) then
        vim.cmd(callback)
      else
        callback()
      end
    else
      if is_a.s(callback) then
        vim.cmd(callback)
      else
        callback(...)
      end
    end
  end

  local id = vim.api.nvim_create_autocmd(event, opts)
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

  dict.update(user.autocmd.ID, id, self)
  dict.update(user.autocmd.GROUP, { augroup, id }, self)

  if name then
    user.autocmd[name] = self
  end
  self.name = name

  return self
end

function Autocmd.disable(self)
  if not self.enabled then
    return
  end
  vim.api.nvim_del_autocmd(self.id)
  self.enabled = false

  return self
end

function Autocmd.delete(self)
  self:disable()

  if self.name then
    user.autocmd[self.name] = nil
  end

  user.autocmd.ID[self.id] = nil
  user.autocmd.GROUP[self.group][self.id] = nil

  return self
end

function Autocmd.replace(self, opts)
  self:delete()

  opts = self.opts or opts
  opts.callback = callback

  return Autocmd(self.event, opts)
end

---
class "Augroup"

Augroup.GROUPS = {}

function Augroup:init(name)
  self.name = name
  self.autocmd = {}
end

function Augroup:add(name, event, opts)
  validate {
    autocmd_name = { "string", name },
    event = { is { "string", "table" }, event },
    opts = {
      {
        __nonexistent = true,
        pattern = is { "string", "table" },
      },
      opts,
    },
  }

  opts.group = self.name
  self.autocmd[name] = Autocmd(event, opts)

  return self
end

function Augroup:remove(name)
  if dict.isblank(self.autocmd) then
    return
  end

  self.autocmd[name]:delete()
  self.autocmd[name] = nil

  return self
end

function Augroup:disable()
  if dict.isblank(self.autocmd) then
    return
  end

  dict.each(self.autocmd, function(au_name, obj)
    obj:delete()
    self.autocmd[au_name] = nil
  end)

  return self
end

function Augroup:delete()
  if self:disable() then
    Augroup.GROUPS[self.name] = nil
  end

  return self
end
