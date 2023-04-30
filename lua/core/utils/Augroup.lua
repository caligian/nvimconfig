--- Augroup wrapper
-- Create augroups via classes. All the instances are stored in
-- user.augroup.
-- @classmod Augroup
require 'core.utils.Autocmd'
Augroup = class "Augroup"

--- Store augroup instances
-- @table user.augroup
user.augroup = user.augroup or {}

--- Contains augroup indexed by ID [number|string]
user.augroup.ID = user.augroup.ID or {}

--- Create an augroup
-- @usage
-- nvim = Augroup('nvim_augroup', true)
--
-- nvim:add(
--   'BufAdd',
--   {
--     pattern = '.config/nvim',
--     callback = function (opts)
--       -- do something
--     end,
--   }
-- )
-- @param name Augroup name
-- @param clear Clear augroup?
-- @return self
function Augroup:init(name, clear)
  self.name = name
  self.autocmd = {}
  self.clear = clear
  self.id = vim.api.nvim_create_augroup(self.name, {clear=clear})

  dict.update(user.augroup, self.name, self)
  dict.update(user.augroup.ID, self.id, self)
end

--- Add autocommand. See ':help nvim_create_autocmd'
-- @param event Autocommand event
-- @param opts Autocommand opts
-- @see Autocmd.init
-- @return self
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

--- Delete autocommand by name
-- @param name autocommand name 
-- @return deleted autocommand
function Augroup:remove(name)
  local exists = self.autocmd[name]
  if not exists then return end

  exists:delete()
  self.autocmd[name] = nil
  
  return exists
end

--- Delete all autocommands
-- @return augroup id
function Augroup:disable()
  if not self.id then return end
  array.each(dict.keys(self.autocmd), function (au_name) self:remove(au_name) end)
  local id = self.id
  vim.api.nvim_del_augroup_by_id(id)
  self.id = false

  return id
end

--- Delete all autocommands and delete reference to this instance
-- @return augroup id
function Augroup:delete()
  local id = self:disable()
  if not id then return end
  user.augroup[self.name] = nil
  user.augroup.ID[id] = nil

  return id
end

return Augroup
