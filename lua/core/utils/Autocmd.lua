--- Neovim autocmd wrapper in class
Autocmd = class "Autocmd"

--- @alias A 
A = Autocmd
user.autocmd = user.autocmd or { ID = {}, GROUP = {}, BUFFER = {} }

function Autocmd:init(event, opts)
  validate {
    event = { is { "string", "table" }, event },
    options = {
      {
        callback = is { "callable", "string" },
        pattern = is { "string", "table" },
      },
      opts,
    },
  }

  opts = copy(opts or {})
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
  self.once = opts.once
  self.nested = opts.nested
  self.name = name

  for key, value in pairs(opts) do
    self[key] = value
  end

  dict.update(user.autocmd.ID, id, self)
  dict.update(user.autocmd.GROUP, { augroup, id }, self)

  if name then user.autocmd[name] = self end

  return self
end

function Autocmd.disable(self)
  if not self.enabled then return end

  vim.api.nvim_del_autocmd(self.id)
  self.enabled = false

  return self
end

function Autocmd.delete(self)
  self:disable()

  dict.delete(user.autocmd, self.name)
  dict.delete(user.autocmd.ID, self.id)
  dict.delete(user.autocmd.GROUP, {self.gid, self.id})

  return self
end

function Autocmd.replace(self, opts)
  self:delete()

  opts = self.opts or opts
  opts.callback = callback

  return Autocmd(self.event, opts)
end

---
Augroup = class "Augroup"

user.augroup = user.augroup or { ID = {} }

function Augroup:init(name, clear)
  self.name = name
  self.autocmd = {}
  self.clear = clear
  self.id = vim.api.nvim_create_augroup(self.name, {clear=clear})

  dict.update(user.augroup, self.name, self)
  dict.update(user.augroup.ID, self.id, self)
end

function Augroup:add(event, opts)
  opts = opts or {}
  opts.group = self.name

  assert(opts.name, 'No autocmd name supplied')

  local au = Autocmd(event, opts)
  self.autocmd[opts.name] = au
  self.autocmd[au.id] = au
  user.augroup.ID[self.id] = self
  user.augroup[self.name] = self

  return self
end

function Augroup:remove(name)
  local exists = self.autocmd[name]
  if not exists then return end
  exists:delete()
  self.autocmd[name] = nil
  
  return self
end

function Augroup:disable()
  if not self.id then return end
  array.each(dict.keys(self.autocmd), function (au_name) self:remove(au_name) end)
  local id = self.id
  vim.api.nvim_del_augroup_by_id(id)
  self.id = false

  return id
end

function Augroup:delete()
  local id = self:disable()
  if not id then return end
  user.augroup[self.name] = nil
  user.augroup.ID[id] = nil

  return id
end
