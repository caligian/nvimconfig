local buffer = require 'core.utils.buffer'
local Term = require "core.utils.Term"
local REPL = class("REPL", Term)
REPL.NoCommandException =
  exception("NoCommandException", "No command given for filetype")
user.repl = user.repl or { FILETYPE = {} }
local state = user.repl.FILETYPE

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

function REPL:scroll_to_bottom()
  return buffer.feedkeys(self.bufnr, 'G')
end

pp(Filetype.get('sh', 'repl'))

function REPL:init(ft)
  ft = ft or vim.bo.filetype
  local is_shell = ft == "sh"
  local cmd = dict.contains(Filetype.ft, ft, "repl")
  local opts = {}

  if not cmd then print(REPL.NoCommandException:throw(ft)) end

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

  array.each({ "split", "float", "center_float", "dock" }, function(f)
    local cb = self[f]
    self[f] = function(self, ...)
      REPL.create(self.filetype)
      return cb(self, ...)
    end
  end)

  local old = self.send
  function self:send(...)
    self:scroll_to_bottom()
    old(self, ...)
  end

  return self
end

function REPL.create(ft, bufnr)
  local exists = REPL.get(ft, bufnr)
  if exists and exists:is_running() then return exists end
  if ft then return REPL(ft):start() end
end

return REPL
