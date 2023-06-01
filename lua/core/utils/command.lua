command = class 'command'
local create = vim.api.nvim_create_user_command
local bufcreate = vim.api.nvim_buf_create_user_command
command.STATE = command.STATE or {}
command.COMMANDS = command.COMMANDS or {}

function command:init(name)
  self.name = name
  self.commands = {}

  command.STATE[name] = self
end

function command:create(name, callback, opts)
  opts = vim.deepcopy(opts or {})
  local bufnr = opts.bufnr
  opts.bufnr = nil

  name = self.name 
    .. name:sub(1, 1):upper()
    .. name:sub(2, #name)

  if bufnr then
    bufcreate(bufnr, name, callback, opts)
  else
    create(name, callback, opts)
  end

  return name
end

function command:add(name, ...)
  return self:create(name, ...)
end

function command.get(name)
  return command.STATE[name]
end

function command.getcommand(name)
  return command.COMMANDS[name]
end

return command
