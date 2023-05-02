--- vim.fn.termopen class wrapper
-- @classmod Term
local Term = class "Term"

--- Contains instances
-- @table user.term
user.term = user.term or {}

--- Contains instances hashed by id
user.term.ID = user.term.ID or {}

--- Default timeout for checking job status
user.term.timeout = user.term.timeout or 30
Term.timeout = user.term.timeout

--- Raised when command is invalid and cannot be run
Term.InvalidCommandException =
  exception("InvalidCommandException", "expected valid command")

--- Raised when command cannot be run
Term.ShellNotExecutableException =
  exception("ShellNotExecutableException", "shell not executable")

--- Raised when command exits with an error
Term.ExitedWithErrorException =
  exception("ExitedWithErrorException", "command exited with error")

--- Raised when job is interrupted
Term.InterruptedException = exception("InterruptedException", "interrupted")

--- Raised when job id is invalid
Term.InvalidIDException =
  exception("InvalidCommandException", "valid id expected")

local function get_status(id)
  if id == 0 then
    return false, "invalid_command"
  elseif id == -1 then
    return false, "not_executable"
  end

  local status = vim.fn.jobwait({ id }, Term.timeout)[1]
  if status ~= -1 and status ~= 0 then
    if status >= 126 then
      return false, "invalid_command"
    elseif status == -2 then
      return false, "interrupted"
    elseif status == -3 then
      return false, "invalid_id"
    end
  end

  return true
end

local function start_term(cmd, opts)
  local scratch = vim.api.nvim_create_buf(false, true)
  local id, term

  vim.api.nvim_buf_call(scratch, function()
    opts = opts or {}
    id = vim.fn.termopen(cmd)
    term = vim.fn.bufnr()
    local ok, msg = get_status(id)
    if not ok then Term[msg]:throw(self) end
  end)

  return id, term
end

--- Wait for timeout and return integer status
-- @tparam[opt] number timeout Wait timeout
-- @return number job status
function Term:wait(timeout)
  if not self.id then return false end

  local status = vim.fn.jobwait({ self.id }, timeout or Term.timeout)
  return status[1]
end

--- Get process status
-- @return boolean_status, exception_name
function Term:get_status()
  if not self.id then return false end
  return get_status(self.id)
end

--- Is process running?
-- @param[opt=false] assrt assert a running process
-- @return boolean
function Term:is_running(assrt)
  if not self.id then return false end
  local ok, msg = get_status(self.id, self.command)
  if not ok and assrt then
    Term[msg]:throw(self)
  elseif not ok then
    return false, msg
  end

  return true
end

--- Start the process
-- @return self
function Term:start()
  if self:is_running() then return self end

  local id, term_buffer = start_term(self.command, self.opts)
  self.id = id
  self.bufnr = term_buffer
  buffer.map(term_buffer, "n", "q", ":hide<CR>", {})

  dict.update(user.term.ID, id, self)

  return self
end

--- Is terminal in a window?
-- @return boolean
function Term:is_visible()
  if self.bufnr then return buffer.is_visible(self.bufnr) end
  return false
end

--- Stop terminal
function Term:stop()
  if not self:is_running() then return end

  self:hide()
  vim.fn.chanclose(self.id)
  self.bufnr = nil
  user.term.ID[self.id] = nil

  return self
end

--- Stop all processes
-- @static
function Term.stopall()
  dict.each(user.term.ID, function(_, obj) obj:stop() end)
end

--- Hide terminal window
-- @see buffer.hide
function Term:hide()
  if self.bufnr then buffer.hide(self.bufnr) end
end

--- Split terminal in a direction
-- @param[opt='s'] direction to split. 'v' for vertical split, 's' for horizontal split
-- @tparam dict opts split options
-- @see buffer.split
function Term:split(direction, opts)
  if not self:is_running() then return end
  if not self:is_visible() then buffer.split(self.bufnr, direction, opts) end
end

--- Open terminal in a floating window
-- @tparam dict opts Floating window options
-- @see buffer.float
function Term:float(opts)
  if not self:is_running() then return end
  if not self:is_visible() and self.bufnr then
    buffer.float(self.bufnr, opts)
  end
end

--- Center-float terminal
-- @tparam dict opts Floating window options
-- @see buffer.float
function Term:center_float(opts)
  self:float(dict.merge({ center = { 0.8, 0.8 } }, opts or {}))
end

--- Dock terminal in a floating window at the bottom
-- @tparam dict opts Floating window options
-- @see buffer.float
function Term:dock(opts) self:float(dict.merge({ dock = 0.3 }, opts or {})) end

--- Send string
-- @tparam string|array[string] string to send
function Term:send(s)
  if not self:is_running() then return end

  local id = self.id
  if is_a.string(s) then s = str.split(s, "[\n\r]+") end
  if self.on_input then s = self.on_input(s) end

  s[#s+1] = "\n"
  s = array.map(s, string.trim)

  return vim.api.nvim_chan_send(id, table.concat(s, "\n"))
end

--- Send current line
-- @param[opt=bufnr()] src_bufnr Buffer index
function Term:send_current_line(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    local s = vim.fn.getline "."
    self:send(s)
  end)
end

--- Send buffer
-- @param[opt=bufnr()] src_bufnr Buffer index
function Term:send_buffer(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end

--- Send everything till current line
-- @param[opt=bufnr()] src_bufnr Buffer index
function Term:send_till_point(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    local line = vim.fn.line "."
    self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
  end)
end

--- Send visual range
-- @param[opt=bufnr()] src_bufnr Buffer index
function Term:send_visual_range(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return self:send(buffer.range(src_bufnr))
end

--- Send 'CTRL-C'
function Term:terminate_input()
  if not self:is_running() then return end

  return self:send(vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
end

--- Constructor. See ':help jobstart()'
-- @param command Command to run
-- @param[opt={}] opts optional options
-- @return self
function Term:init(cmd, opts)
  validate {
    command = { is { "string", "table" }, cmd },
    ["?opts"] = {
      { __nonexistent = true, ["?on_input"] = "callable" },
      opts,
    },
  }

  opts = opts or {}
  self.command = cmd
  self.opts = opts
  self.on_input = opts.on_input

  return self
end

return Term
