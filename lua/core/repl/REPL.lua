if not REPL then
  class("REPL", Term)
end

REPL.ids = REPL.ids or {}

function REPL.get(ft, bufnr)
  if ft == "sh" then
    local exists = REPL.ids.sh
    if exists and exists:is_running() then
      return exists
    end
  end

  ft = ft or vim.bo.filetype
  bufnr = bufnr or vim.fn.bufnr()
  local exists = table.get(REPL.ids, { ft, bufnr })
  if exists and exists:is_running() then
    return exists
  end
end

function REPL:init(ft)
  ft = ft or vim.bo.filetype
  local is_shell = ft == "sh"
  local cmd = table.contains(Lang.langs, ft, "repl")
  local opts = {}

  if not cmd then
    throw_error { success = false, reason = "no_command", ft = ft }
  else
    if is_a.t(cmd) then
      opts.on_input = cmd.on_input
      cmd = cmd[1]
    end
  end

  local exists
  local bufnr = vim.fn.bufnr()

  REPL:super()(self, cmd, opts)

  if is_shell then
    self.shell = true
    REPL.ids.sh = self
  else
    table.update(REPL.ids, { ft, bufnr }, self)
  end

  self.filetype = self

  return self
end

table.each({ "send", "split", "float", "center_float", "dock" }, function(f)
  local cb = REPL[f]
  REPL[f] = function(self, ...)
    self:start()
    return cb(self, ...)
  end
end)
