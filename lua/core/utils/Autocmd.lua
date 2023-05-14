--- Autocommand wrapper
-- Create autocommands via classes. All the instances are stored in
-- user.autocmd.
-- @classmod Autocmd
-- @alias A
Autocmd = class "Autocmd"
A = Autocmd
user.autocmd = user.autocmd or { ID = {}, GROUP = {}, BUFFER = {} }
user.augroup = user.augroup or {ID={}}

--- Store autocommand instances
-- @table user.autocmd
user.autocmd = user.autocmd or {}

--- Contains instances hashed by id
user.autocmd.ID = user.autocmd.ID or {}

--- Contains instances hashed by buffer
user.autocmd.BUFFER = user.autocmd.BUFFER or {}

user.autocmd.AUTOCMD_ID = user.autocmd.AUTOCMD_ID or 1

--- Create an autocommand
-- @usage
-- -- `:help autocmd`
-- local a = Autocmd(
--  'BufEnter',
--  {callback=partial(print, 'hello'), pattern='*'}
-- )
-- @param event string|array[string] of vim events
-- @param opts opts
-- @param opts.callback callable|string. Mandatory param
-- @param opts.pattern Autocommand pattern. Mandatory param
-- @param opts.once Run once?
-- @param opts.nested Nested autocommands?
-- @param opts.name Unique autocommand name
-- @param opts.bufnr Buffer index
-- @return self
function Autocmd:init(event, opts)
  opts = utils.copy(opts)

  validate {
    event = { is { "string", "table" }, event },
    options = {
      {
        callback = is { "callable", "string" },
        pattern = is { "string", "table" },
        opt_bufnr = "number",
      },
      opts,
    },
  }

  local name = opts.name
  opts.name = nil
  if not name then
    name = user.autocmd.AUTOCMD_ID
    user.autocmd.AUTOCMD_ID = user.autocmd.AUTOCMD_ID + 1
  end

  if opts.bufnr then
    opts.pattern = sprintf('<buffer=%d>', opts.bufnr)
    opts.bufnr = nil
  end

  local callback = opts.callback
  opts.callback = function(...)
    if opts.once then
      if is_a.string(callback) then
        vim.cmd(callback)
      else
        callback()
      end
      self.enabled = false
    else
      if is_a.string(callback) then
        vim.cmd(callback)
      else
        callback(...)
      end
    end
  end

  opts.group = opts.group or 'user_default'
  local clear_group = opts.clear_group
  opts.clear_group = nil
  if clear_group == nil then clear_group = false end

  self.gid = vim.api.nvim_create_augroup(opts.group, {clear=clear_group})
  self.name = opts.group .. '.' .. name
  self.id = vim.api.nvim_create_autocmd(event, opts)
  self.group = group

  dict.merge(self, opts)
  dict.update(user.autocmd, self.name, self)
  dict.update(user.autocmd.ID, self.id, self)

  return self
end

--- Disable autocommand
function Autocmd:disable()
  if not self.enabled then return end

  vim.api.nvim_del_autocmd(self.id)
  self.enabled = false

  return self
end

--- Delete autocommand instance reference in user.autocmd
function Autocmd:delete()
  self:disable()

  dict.delete(user.autocmd, self.name)
  dict.delete(user.autocmd.ID, self.id)

  return self
end

function Autocmd.bind(autocmds)
  dict.each(autocmds, function(name, x)
    if x.group then
      array.each(x, function(au) 
        au.group = x.group
        Autocmd(unpack(au))
      end)
    else
      x[2].name = name
      Autocmd(unpack(x))
    end
  end)
end

return Autocmd
