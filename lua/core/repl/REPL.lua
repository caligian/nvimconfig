if not REPL then class("REPL", Term) end
local exception = Exception "REPLException"
exception.no_command = "No command given for filetype"
user.repl = user.repl or {}

function REPL.get(ft, bufnr)
  if ft == "sh" then
    local exists = user.repl.sh
    if exists and exists:is_running() then
      return exists
    end
  end

  ft = ft or vim.bo.filetype
  bufnr = bufnr or vim.fn.bufnr()
  local exists = dict.get(user.repl, { ft, bufnr })
  if exists and exists:is_running() then
    return exists
  end
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
    user.repl.sh = self
  else
    dict.update(user.repl, { ft, bufnr }, self)
  end

  self.filetype = self

  return self
end

function REPL.create(ft)
  local exists = REPL.get(ft)
  if exists and exists:is_running() then return exists end
  return REPL(ft)
end

array.each({ "send", "split", "float", "center_float", "dock" }, function(f)
  local cb = REPL[f]
  REPL[f] = function(self, ...)
    self:start()
    return cb(self, ...)
  end
end)
