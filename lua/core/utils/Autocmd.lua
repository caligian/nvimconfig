--- Autocommand wrapper
-- Create autocommands via classes. All the instances are stored in
-- user.autocmd.
-- @classmod Autocmd
-- @alias A
Autocmd = class "Autocmd"
A = Autocmd
user.autocmd = user.autocmd or { ID = {}, GROUP = {}, BUFFER = {} }

--- Store autocommand instances
-- @table user.autocmd
user.autocmd = user.autocmd or {}

--- Contains instances hashed by id
user.autocmd.ID = user.autocmd.ID or {}

--- Contains instances hashed by augroup
user.autocmd.GROUP = user.autocmd.GROUP or {}

--- Contains instances hashed by buffer
user.autocmd.BUFFER = user.autocmd.BUFFER or {}

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
  validate {
    event = { is { "string", "table" }, event },
    options = {
      {
        __nonexistent = true,
        callback = is { "callable", "string" },
        pattern = is { "string", "table" },
        opt_bufnr = "number",
        opt_name = "string",
      },
      opts,
    },
  }

  opts = copy(opts or {})
  local augroup
  local group = copy(opts.group or {})
  local name = opts.name
  local bufnr = opts.bufnr
  opts.name = nil
  opts.bufnr = nil
  if bufnr then opts.pattern = "<buffer=" .. bufnr .. ">" end

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

  local id = vim.api.nvim_create_autocmd(event, opts)
  self.id = id
  self.gid = augroup
  self.group = group
  self.event = event
  self.enabled = true
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
  dict.delete(user.autocmd.GROUP, { self.gid, self.id })

  return self
end

function Autocmd.bind(autocmds)
  dict.each(autocmds, function(name, x)
    if x.group then
      local augroup = Augroup(name)
      array.each(x, function(au) augroup:add(unpack(au)) end)
    else
      x[2].name = name
      Autocmd(unpack(x))
    end
  end)
end

local init = Autocmd.init
Autocmd.init = multimethod()

Autocmd.init:set(
  function(self, event, pattern, callback, opts)
    local options = utils.copy(opts or {})
    options.callback = callback
    options.pattern = pattern

    return init(self, event, options)
  end,
  Autocmd,
  { "string", "table" },
  { "string", "table" },
  { "string", "callable" }
)

Autocmd.init:set(
  function (self, event, opts)
    return init(self, event, opts)
  end,
  Autocmd,
  {'string', 'table'},
  'table'
)

return Autocmd
