class("Process")

Process.id = Process.id or {}

local function get(id)
  return Process.id[id]
end

local function parse(d, out)
  if type(d) == "string" then
    d = vim.split(d, "\n")
  elseif type(d) == "table" then
    for _, s in ipairs(d) do
      s = vim.split(s, "\n")
      V.extend(out, s)
    end
  end
end

function Process:_on_exit(cb)
  return vim.schedule_wrap(function(j, exit_code)
    j = get(j)
    j.exited = true
    j.exit_code = exit_code
    j.running = false

    if cb then
      cb(j)
    end
  end)
end

function Process:_on_stderr(cb)
  self.stderr = self.stderr or {}
  local stderr = self.stderr

  return vim.schedule_wrap(function(j, d)
    if d then
      V.extend(stderr, parse(d, self.stderr))
    end
    if cb then
      cb(get(j))
    end
  end)
end

function Process:_on_stdout(cb)
  self.stdout = self.stdout or {}
  local stdout = self.stdout

  return vim.schedule_wrap(function(j, d)
    if d then
      V.extend(stdout, parse(d, self.stdout))
    end
    if cb then
      cb(get(j))
    end
  end)
end

function Process:_init(command, opts)
  self.command = command
  self.running = false
  self.init = false

  opts = opts or {}
  opts.env = opts.env or {
    HOME = os.getenv("HOME"),
    PATH = os.getenv("PATH"),
  }
  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.stdin = opts.stdin == nil and "pipe" or opts.stdin

  for k, v in pairs(opts) do
    self[k] = v
  end

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
    opts.on_stdout = self:_on_exit()
  else
    local current = opts.on_exit
    opts.on_exit = self:_on_exit(current)
  end

  self.init = true
  self._opts = opts

  return self
end

function Process:run()
  if not self:running() then
    return
  end

  local id = vim.fn.jobstart(self.command, self._opts)
  assert(id ~= -1, "Could not start job with command " .. self.command)

  self.id = id
  self.running = true
  V.update(Process.id, { id }, self)

  return self
end

function Process:status(timeout)
  timeout = timeout or 0
  return vim.fn.jobwait({ self.id }, timeout)[1]
end

function Process:is_invalid()
  return self:status() == -3
end

function Process:is_interrupted()
  return self:status() == -2
end

function Process:is_running(timeout)
  local status = self:status(timeout) == -1
  self.running = status

  return status
end

function Process:wait(timeout)
  if not self:is_running() then
    return
  end

  return vim.fn.jobwait({ self.id }, timeout)
end
