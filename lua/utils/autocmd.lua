-- Autocmd
class("Autocmd")
Autocmd.id = Autocmd.id or {}
Autocmd.group = Autocmd.group or {}

local function autocmd(event, opts)
  assert(V.istable(opts))
  assert(opts.pattern)
  assert(opts.callback)

  opts.group = opts.group or "UserGlobal"

  return V.autocmd(event, opts)
end

function Autocmd._init(self, event, opts)
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

  for key, value in pairs(opts) do
    if not key:match("group") then
      self[key] = value
    end
  end

  V.update(Autocmd.id, id, self)
  V.update(Autocmd.group, { augroup, id }, self)

  return self
end

function Autocmd.disable(self)
  if not self.enabled then
    return
  end
  vim.api.nvim_del_autocmd(self.id)
  self.enabled = false
end

function Autocmd.delete(self)
  self:disable()
  Autocmd.id[self.id] = nil
  self.autocmd[self.id] = nil
end
