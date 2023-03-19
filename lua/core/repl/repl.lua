require "utils.terminal"

if not REPL then class("REPL", Term) end

REPL.ids = REPL.ids or {}

function REPL:_init(is_shell)
  local ft = is_shell and "sh" or vim.bo.filetype
  local cmd = table.contains(Lang.langs, ft, "repl")

  if not cmd then
    throw_error {success=false, reason='no_command',  ft=ft}
  end


  local exists
  local bufnr = vim.fn.bufnr()

  if not is_shell then
    exists = table.contains(REPL.ids, ft, bufnr)
  else
    exists = REPL.ids.sh
  end

  if exists and exists:is_running() then return exists end

  Term._init(self, cmd)

  if is_shell then
    self.shell = true
    REPL.ids.sh = self
  else
    table.update(REPL.ids, { ft, bufnr }, self)
  end

  return self
end
