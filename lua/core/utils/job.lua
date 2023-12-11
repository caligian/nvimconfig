require "core.utils.shlex"
local uv = vim.loop

--- @class job

job = job
  or struct("job", {
    "exit_code",
    "cmd",
    "args",
    "pipes",
    "lines",
    "errors",
    "handle",
    "check",
    "output_buffer",
    "stdout_buffer",
    "stderr_buffer",
    "cwd",
  })

function job.mkpipes(self)
  self.pipes = {}
  local stdout, stderr, stdin

  stdout = uv.new_pipe()
  stderr = uv.new_pipe()
  stdin = uv.new_pipe()

  self.pipes.stdout = stdout
  self.pipes.stderr = stderr
  self.pipes.stdin = stdin
end

function job.opts(self, opts)
  opts = opts or {}
  self.pipes = self.pipes or {}

  return dict.merge(opts, {
    args = self.args,
    stdio = { self.pipes.stdin, self.pipes.stdout, self.pipes.stderr },
  })
end

function job.init(self, cmd, opts)
  opts = deepcopy(opts or {})
  local cwd = opts.cwd or path.dirname(buffer.name())
  opts.cwd = nil
  self.cmd = cmd
  self.cwd = cwd
  local args = opts.args
  local check = uv.new_check()
  local stdout = opts.stdout
  local stderr = opts.stderr
  local output = opts.output
  local bufsplit = opts.split
  local float = opts.float
  local before = opts.before
  local on_exit = opts.on_exit
  local stdout_buffer = opts.stdout_buffer
  local stderr_buffer = opts.stderr_buffer
  local output_buffer = opts.output_buffer
  opts.on_exit = nil

  if split or float then
    output_buffer = buffer.scratch()
    output = true
  end

  if output then
    if not output_buffer then
      stdout_buffer = buffer.scratch()
      stderr_buffer = buffer.scratch()
    else
      output_buffer = buffer.scratch()
    end

    if iscallable(output) then
      stdout = output
      stderr = output
    else
      stdout = true
      stderr = true
    end
  end

  local function has_lines(lines)
    if not lines then
      return false
    elseif #lines == 0 then
      return false
    elseif #lines[1] == 0 then
      return false
    end

    return true
  end

  local function write_output(cls)
    if output_buffer then
      local cmd_s = "COMMAND: " .. cls.cmd
      local lines = { cmd_s, "" }
      local ok_lines = has_lines(cls.lines)
      local ok_errors = has_lines(cls.errors)

      if ok_lines then
        list.append(lines, "STDOUT", "")
        list.extend(lines, cls.lines)
      end

      if ok_errors then
        list.append(lines, "STDERR", "")
        list.extend(errors, cls.errors)
      end

      buffer.set_lines(output_buffer, 0, -1, lines)
    elseif stdout_buffer or stderr_buffer then
      local lines = cls.lines
      local errors = cls.errors

      if stdout_buffer and has_lines(lines) then
        buffer.set_lines(stdout_buffer, 0, -1, lines)
      end

      if stderr_buffer and has_lines(errors) then
        buffer.set_lines(stderr_buffer, 0, -1, errors)
      end
    end

    if bufsplit == true then
      bufsplit = "botright split"
    elseif float == true then
      float = { center = { 100, 30 }, relative = "editor" }
    end

    if bufsplit then
      if output_buffer then
        buffer.split(output_buffer, bufsplit)
      else
        if stdout_buffer then
          buffer.split(stdout_buffer, bufsplit)
        end

        if stderr_buffer then
          buffer.split(stderr_buffer, bufsplit)
        end
      end

      buffer.call(out_buf, function()
        vim.cmd "resize 15"
      end)
    elseif float then
      if output_buffer then
        buffer.float(output_buffer, float)
      else
        if stdout_buffer then
          buffer.float(stdout_buffer, float)
        end

        if stderr_buffer then
          buffer.float(stderr_buffer, float)
        end
      end
    end
  end

  job.mkpipes(self)
  job.opts(self, opts)

  cmd = isstring(cmd) and shlex.parse(cmd) or cmd
  if istable(cmd) then
    opts.args = list.sub(cmd, 2, -1)
    cmd = cmd[1]
  end

  if before then
    before()
  end

  local fh = uv.spawn(
    cmd,
    opts,
    vim.schedule_wrap(function(code, _)
      check:stop()
      self.exit_code = code
      job.close(self)

      if on_exit then
        on_exit(self)
      end

      write_output(self)
    end)
  )

  if not fh then
    error("could not run command: " .. cmd)
  end

  check:start(function()
    if job.isclosing(self, true) then
      job.close(self)
    end
  end)

  self.check = check
  self.handle = fh
  self.lines = {}
  self.errors = {}
  self.args = args
  self.output_buffer = output_buffer
  self.stdout_buffer = stdout_buffer
  self.stderr_buffer = stderr_buffer

  if stdout or stderr then
    local function collect(err, data, tp)
      if err then
        list.extend(self.errors, err)
      elseif data then
        data = vim.split(data, "\n")
        list.extend(self.lines, data)
      end

      if tp == "stdout" and iscallable(stdout) then
        stdout(self.lines)
      elseif tp == "stderr" and iscallable(stderr) then
        stderr(self.lines)
      end
    end

    if stdout then
      uv.read_start(self.pipes.stdout, function(err, data)
        collect(err, data, "stdout")
      end)
    end

    if stderr then
      uv.read_start(self.pipes.stderr, function(err, data)
        collect(err, data, "stderr")
      end)
    end
  end

  return self
end

function job.wait(self, timeout, tries, inc)
  if self.exit_code then
    return true
  elseif not self.handle or not uv.is_active(self.handle) then
    return false
  end

  timeout = timeout or 50
  tries = tries or 10
  inc = inc or timeout / 5
  local i = 0

  while i <= tries do
    if self.exit_code then
      break
    elseif uv.is_closing(self.handle) then
      break
    elseif job.isclosing(self, "stdout") or job.isclosing(self, "stderr") then
      break
    end

    vim.wait(timeout)

    timeout = timeout + inc
    i = i + 1
    inc = timeout / 10
  end

  return self.exit_code ~= nil
end

function job.wait_for_output(self, timeout, tries, inc)
  if job.wait(self, timeout, tries, inc) then
    return { stdout = self.lines, stderr = self.errors }
  end

  return false
end

function job.close(self)
  if self.handle:is_closing() then
    return
  end

  self.pipes.stdout:shutdown()
  self.pipes.stderr:shutdown()
  self.handle:close()

  return self
end

function job.isactive(self)
  if not self.handle then
    return false
  elseif not uv.is_active(self.handle) then
    return false
  end

  return true
end

function job.isclosing(self, pipes)
  if not self.handle then
    return false
  elseif pipes == true then
    return self.pipes.stdin and uv.is_closing(self.pipes.stdin),
      self.pipes.stdout and uv.is_closing(self.pipes.stdout),
      self.pipes.stderr and uv.is_closing(self.pipes.stderr)
  elseif pipes == "stdout" then
    return self.pipes.stdout and uv.is_closing(self.pipes.stdout)
  elseif types == "stdin" then
    return self.pipes.stdin and uv.is_closing(self.pipes.stdin)
  elseif types == "stderr" then
    return self.pipes.stderr and uv.is_closing(self.pipes.stderr)
  else
    return uv.is_closing(self.handle)
  end
end

function job.close_stderr_pipe(self)
  if self.pipes.stderr and not uv.is_closing(self.pipes.stderr) then
    self.pipes.stderr:shutdown()
    return true
  end

  return false
end

function job.close_stdin_pipe(self)
  if self.pipes.stdin and not uv.is_closing(self.pipes.stdin) then
    self.pipes.stdin:shutdown()
    return true
  end

  return false
end

function job.close_stdout_pipe(self)
  if self.pipes.stdout and not uv.is_closing(self.pipes.stdout) then
    self.pipes.stdout:shutdown()
    return true
  end

  return false
end

function job.close_pipes(self)
  return job.close_stdout_pipe(self), job.close_stderr_pipe(self), job.close_stdin_pipe(self)
end

function job.send(self, s)
  if not self.handle or not uv.is_active(self.handle) then
    return false
  elseif job.isclosing(self, "stdin") then
    return false
  end

  return uv.write(self.pipes.stdin, split(s, "\n"))
end

function job.oneshot(cmd, opts)
  opts = copy(opts or {})
  opts.output = true

  return job(cmd, opts)
end

jobx = class "jobx"
dict.merge(jobx, job)
