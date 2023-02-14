-- Autocmd
class("Autocmd")

Autocmd.id = Autocmd.id or {}
Autocmd.defaults = Autocmd.defaults or {}
Autocmd.group = Autocmd.group or {}

function Autocmd:_init(event, opts)
  assert(V.istable(opts))
  assert(opts.callback)
  assert(opts.pattern)

  local augroup
  local group = V.deepcopy(opts.group or {})
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

  for key, value in pairs(opts) do
    self[key] = value
  end

  V.update(Autocmd.id, id, self)
  V.update(Autocmd.group, { augroup, id }, self)

  return self
end

function Autocmd:disable()
  if not self.enabled then
    return
  end
  vim.api.nvim_del_autocmd(self.id)
  self.enabled = false
end

function Autocmd:delete()
  self:disable()
  Autocmd.id[self.id] = nil
  Autocmd.group[self.group][self.id] = nil

  return self
end

function Autocmd:replace(callback)
  self:delete()
  local opts = self.opts
  opts.callback = callback

  return Autocmd(self.event, opts)
end
