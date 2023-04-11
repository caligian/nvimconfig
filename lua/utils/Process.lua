class "Process"

Process.ids = Process.ids or {}

local function parse(d, out)
  if type(d) == "string" then
    d = vim.split(d, "\n")
  elseif type(d) == "table" then
    for _, s in ipairs(d) do
      s = vim.split(s, "\n")
      table.extend(out, s)
    end
  end
end

function Process._on_exit(self, cb)
  return vim.schedule_wrap(function(j, exit_code)
    j = Process.ids[j]
    j.exited = true
    j.exit_code = exit_code

    if cb then
      cb(j)
    end
  end)
end

function Process._on_stderr(self, cb)
  self.stderr = self.stderr or {}
  local stderr = self.stderr

  return vim.schedule_wrap(function(j, d)
    if d then
      table.extend(stderr, parse(d, self.stderr))
    end
    if cb then
      cb(table.get(j))
    end
  end)
end

function Process._on_stdout(self, cb)
  self.stdout = self.stdout or {}
  local stdout = self.stdout

  return vim.schedule_wrap(function(j, d)
    if d then
      table.extend(stdout, parse(d, self.stdout))
    end
    if cb then
      cb(table.get(j))
    end
  end)
end

function Process.init(self, command, opts)
  validate {
    command = { "string", command },
    ["?opts"] = { "table", opts },
  }

  opts = opts or {}

  validate { opts = { "table", opts } }

  opts = opts or {}
  opts.env = opts.env or {
    HOME = os.getenv "HOME",
    PATH = os.getenv "PATH",
  }
  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.stdin = opts.stdin == nil and "pipe" or opts.stdin

  if not opts.terminal then
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
  else
    -- For the terminal buffer
    self.buffer = Buffer(false, true)
  end

  if not opts.on_exit then
    opts.on_exit = self:_on_exit()
  else
    local current = opts.on_exit
    opts.on_exit = self:_on_exit(current)
  end

  self.command = command
  self.opts = opts

  return table.lmerge(self, opts)
end

function Process.status(self, timeout)
  if not self.id then
    return false
  end

  timeout = timeout or 0
  return vim.fn.jobwait({ self.id }, timeout)[1]
end

function Process.is_invalid(self)
  return self:status() == -3
end

function Process.is_interrupted(self)
  return self:status() == -2
end

function Process.is_running(self, timeout)
  return self:status(timeout) == -1
end

function Process.wait(self, timeout)
  if not self:is_running() then
    return
  end

  return vim.fn.jobwait({ self.id }, timeout)
end

function Process.run(self)
  if self:is_running() then
    return
  end

  local id
  if self.terminal then
    id = self.buffer:call(function()
      return vim.fn.termopen(self.command, self.opts)
    end)
  else
    id = vim.fn.jobstart(self.command, self.opts)
  end

  assert(id ~= -1, "Could not start job with command " .. self.command)

  self.id = id

  table.update(Process.ids, { id }, self)

  return self
end

function Process.send(self, s)
  if not self:is_running() then
    return
  end

  validate {
    s = is { "s", "t" },
  }

  if is_a.t(s) then
    s = table.concat(s, "\n")
  end

  vim.api.nvim_chan_send(self.id, s)

  return self
end

function Process.stop(self)
  if not self:is_running() then
    return
  end

  vim.fn.chanclose(self.id)
  if self.buffer then
    self.buffer:delete()
  end
  self.buffer = nil

  return self
end

function Process.stopall()
  table.each(table.values(Process.ids), function(p)
    p:stop()
  end)
end
