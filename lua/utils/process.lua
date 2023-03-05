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

new 'Process' {
  process = {},

  _on_exit = function(cb)
    return vim.schedule_wrap(function(j, exit_code)
      j = get(j)
      j.exited = true
      j.exit_code = exit_code

      if cb then
        cb(j)
      end
    end)
  end,

  _on_stderr = function(cb)
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
  end,

  _on_stdout = function(cb)
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
  end,

  _init = function(command, opts)
    assert(V.isstring(command) or V.istable(command))

    opts = opts or {}

    assert(V.istable(opts))

    opts = opts or {}
    opts.env = opts.env or {
      HOME = os.getenv("HOME"),
      PATH = os.getenv("PATH"),
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

    return V.lmerge(self, opts)
  end,

  status = function(timeout)
    if not self.id then
      return false
    end

    timeout = timeout or 0
    return vim.fn.jobwait({ self.id }, timeout)[1]
  end,

  is_invalid = function()
    return self:status() == -3
  end,

  is_interrupted = function()
    return self:status() == -2
  end,

  is_running = function(timeout)
    return self:status(timeout) == -1
  end,

  wait = function(timeout)
    if not self:is_running() then
      return
    end

    return vim.fn.jobwait({ self.id }, timeout)
  end,

  run = function()
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

    V.update(Process.process, { id }, self)

    return self
  end,

  send = function(s)
    if not self:is_running() then
      return
    end

    assert(V.isstring(s) or V.istable(s))

    if V.istable(s) then
      s = table.concat(s, "\n")
    end

    return vim.api.nvim_chan_send(self.id, s)
  end,

  stop = function()
    if not self:is_running() then
      return
    end

    vim.fn.chanclose(self.id)
    if self.buffer then
      self.buffer:delete()
    end
    self.buffer = nil
  end,

  stopall = function()
    V.each(V.values(Process.process), function(p)
      p:stop()
    end)
  end,
}
