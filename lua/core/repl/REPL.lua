local Term = require 'utils.Term'
local REPL = Class.new("REPL", Term)
local exception = Exception "REPLException"
exception.no_command = "No command given for filetype"
user.repl = user.repl or {FILETYPE={}}
local state =  user.repl.FILETYPE

function REPL.get(ft, bufnr)
  if ft == "sh" then
    local exists = state.sh
    if exists and exists:is_running() then return exists end
  end

  ft = ft or vim.bo.filetype
  bufnr = bufnr or vim.fn.bufnr()
  local exists = dict.get(state, { ft, bufnr })
  if exists and exists:is_running() then return exists end
end

function REPL:init(ft)
  ft = ft or vim.bo.filetype
  local is_shell = ft == "sh"
  local cmd = dict.contains(Lang.langs, ft, "repl")
  local opts = {}

  exception.no_command:throw_unless(cmd, self)

  if is_a.table(cmd) then
    opts.on_input = cmd.on_input
    cmd = cmd[1]
  end

  local bufnr = vim.fn.bufnr()
  REPL:super()(self, cmd, opts)

  if is_shell then
    self.shell = true
    user.repl.FILETYPE.sh = self
  else
    dict.update(state, { ft, bufnr }, self)
  end

  self.filetype = ft

  array.each({ "send", "split", "float", "center_float", "dock" }, function(f)
    local cb = self[f]
    self[f] = function(self, ...)
      REPL.create(self.filetype) 
      return cb(self, ...)
    end
  end)

  return self
end

function REPL.create(ft, bufnr)
  local exists = REPL.get(ft, bufnr)
  if exists and exists:is_running() then return exists end
  return REPL(ft):start()
end

return REPL
