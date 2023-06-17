--- vim.fn.jobstart class wrapper for async job control
-- @classmod Process

local Process = class "Process"

--- Contains instances
user.process = user.process or {}

--- Contains instances hashed by id
user.process.ID = user.process.ID or {}

--- Default timeout for checking job status
user.timeout = user.timeout or 30

--- Default timeout for checking job status
Process.timeout = user.timeout

--- Raised when command is invalid and cannot be run
Process.InvalidCommandException =
  exception "expected valid command"

--- Raised when command cannot be run
Process.ShellNotExecutableException =
  exception "shell not executable"

--- Raised when command exits with an error
Process.ExitedWithErrorException =
  exception "command exited with error"

--- Raised when job is interrupted
Process.InterruptedException = exception "interrupted"

--- Raised when job id is invalid
Process.InvalidIDException =
  exception "valid id expected"

local function get_status(id, cmd)
  if id == 0 then
    return false, "invalid_command"
  elseif id == -1 then
    return false, "not_executable"
  end

  local status = vim.fn.jobwait({ id }, Term.timeout)[1]
  if status ~= -1 and status ~= 0 then
    if status >= 126 then
      return false, "InvalidCommandException"
    elseif status == -2 then
      return false, "InterruptedException"
    elseif status == -3 then
      return false, "InvalidIDException"
    end
  end

  return true
end

local function parse(d, out)
  if type(d) == "string" then
    d = vim.split(d, "\n")
  elseif type(d) == "table" then
    for _, s in ipairs(d) do
      s = vim.split(s, "\n")
      array.extend(out, s)
    end
  end
end

function Process:_on_exit(cb)
  return vim.schedule_wrap(function(j, exit_code)
    j = user.process.ID[j]
    j.exited = true
    j.exit_code = exit_code

    if cb then
      cb(j, exit_code)
    end
  end)
end

function Process:_on_stderr(cb)
  self.stderr = self.stderr or {}
  local stderr = self.stderr

  return vim.schedule_wrap(function(_, d)
    if d then
      parse(d, self.stderr)
    end
    if cb then
      cb(self, d)
    end
  end)
end

function Process:_on_stdout(cb)
  self.stdout = self.stdout or {}
  local stdout = self.stdout
  return vim.schedule_wrap(function(_, d)
    if d then parse(d, self.stdout) end
    if cb then cb(self, d) end
  end)
end

--- Constructor. See ':help jobstart()'
-- @param command Command to run
-- @param[opt={}] opts optional options
-- @return self
function Process:init(command, opts)
  validate {
    command = { "string", command },
    ["?opts"] = { "table", opts },
  }

  opts = opts or {}
  opts.env = opts.env or { HOME = os.getenv "HOME", PATH = os.getenv "PATH" }
  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.stdin = opts.stdin == nil and "pipe" or opts.stdin

  if not opts.on_stderr then
    opts.on_stderr = self:_on_stderr()
  else
    local current = opts.on_stderr
    opts.on_stderr = self:_on_stderr(current)
  end

  if not opts.on_stdout then
    opts.on_stdout = self:_on_stdout()
  else
    local current = opts.on_stdout
    opts.on_stdout = self:_on_stdout(current)
  end

  if not opts.on_exit then
    opts.on_exit = self:_on_exit()
  else
    local current = opts.on_exit
    opts.on_exit = self:_on_exit(current)
  end

  self.command = command
  self.opts = opts

  return dict.lmerge(self, opts)
end

--- Stop process
-- @return self
function Process:stop()
  if not self:is_running() then
    return
  end

  self:hide()
  vim.fn.chanclose(self.id)
  self.bufnr = nil
  user.process.ID[self.id] = nil

  return self
end

--- Stop all processes
-- @static
function Process.stopall()
  dict.each(user.process.ID, function(obj)
    obj:stop()
  end)
end

--- Get process status
-- @return boolean_status, exception_name
function Process:get_status()
  return get_status(self.id, self.command)
end

--- Is process running?
-- @param[opt=false] assrt assert a running process
-- @return boolean
function Process:is_running(assrt)
  if not self.id then
    return false
  end
  local ok, msg = get_status(self.id, self.command)
  if not ok and assrt then
    Process[msg]:throw(self)
  elseif not ok then
    return false, msg
  end

  return true
end

--- Wait for timeout and return integer status
-- @tparam[opt] number timeout Wait timeout
-- @return number job status
function Process:wait(timeout)
  if not self:is_running() then
    return
  end

  return vim.fn.jobwait({ self.id }, timeout)
end

--- Start the process
-- @return self
function Process:start()
  if self:is_running() then
    return
  end

  local id
  id = vim.fn.jobstart(self.command, self.opts)
  local ok, msg = get_status(id)

  if not ok then
    Process[msg]:throw(self.command)
  end

  self.id = id
  dict.update(user.process.ID, { id }, self)

  return self
end

--- Send string to process
-- @tparam array[string]|string s String to send
function Process:send(s)
  local id = self.id
  if is_a.string(s) then
    s = string.split(s, "[\n\r]")
  end
  if self.on_input then
    s = self.on_input(s)
  end
  s[#s + 1] = "\n"
  vim.api.nvim_chan_send(id, table.concat(s, "\n"))
end

return Process
