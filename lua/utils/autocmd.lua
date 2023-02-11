-- Augroup
class('Augroup')
Augroup.id = Augroup.id or {}

function Augroup._init(self, group, opts)
  opts = opts or {}
  for key, value in pairs(opts) do
    self[key] = value
  end
  self.name = group
  self.id = vim.api.nvim_create_augroup(group, opts)

  if Augroup.id[self.id] then
    return Augroup.id[self.id]
  else
    V.update(Augroup.id, self.id, self)
    self.enabled = true
    self.autocmd = {}

    return self
  end
end

function Augroup.clear(self)
  vim.cmd(sprintf('augroup %s | au! | augroup END', self.name))
  for _, autocmd in pairs(self.autocmd) do
    autocmd:delete()
  end
  self.autocmd = {}
end

function Augroup.delete(self)
  if not self.enabled then return end

  self.enabled = false
  self:clear()
  vim.api.nvim_del_augroup_by_id(self.id)
end

-- Autocmd
class('Autocmd')
Autocmd.id = Autocmd.id or {}

function Autocmd._init(self, event, opts)
  opts = opts or {}
  opts.group = opts.group or 'UserGlobal'
  local augroup = Augroup(opts.group, { clear = opts.clear_group })
  opts.clear_group = nil

  assert(opts.callback, 'No callback given')
  assert(opts.pattern, 'No pattern given')

  local _callback = opts.callback
  opts.callback = function()
    if V.isstring(_callback) then
      vim.cmd(_callback)
    else
      _callback()
    end
  end

  if opts.once then
    local _cb = callback
    callback = function()
      _cb()
      self.enabled = false
    end
  end

  self.augroup = augroup
  self.id = vim.api.nvim_create_autocmd(event, opts)
  self.augroup[self.id] = self

  return V.lmerge(self, opts)
end

function Autocmd.disable(self)
  if not self.enabled then return end
  vim.api.nvim_del_autocmd(self.id)
  self.enabled = false
end

function Autocmd.delete(self)
  self:disable()
  Autocmd.id[self.id] = nil
  self.autocmd[self.id] = nil
end
