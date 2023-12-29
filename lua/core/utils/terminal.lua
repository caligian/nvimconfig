require "core.utils.buffer.buffer"

Terminal = class 'Terminal'
user.terminals = user.terminals or {}

Terminal.exceptions = {
  invalid_command = "expected valid command",
  shell_not_executable = "shell not executable",
  exited_with_error = "command exited with error",
  interrupted = "Terminal interrupted",
  invalid_id = "invalid job id",
  no_default_command = "no default command provided",
}

Terminal.timeout = 200

function Terminal.isa(x)
  return mtget(x) == "Terminal"
end

function Terminal.opts(opts)
  return {
    clear_env = opts.clear_env,
    cwd = opts.cwd,
    detach = opts.detach,
    env = opts.env,
    height = opts.height,
    on_exit = opts.on_exit,
    on_stdout = opts.on_stdout,
    on_stderr = opts.on_stderr,
    overlapped = opts.overlapped,
    pty = opts.pty,
    rpc = opts.rpc,
    stderr_buffered = opts.stderr_buffered,
    stdout_buffer = opts.stdout_buffered,
    stdin = opts.stdin,
    width = opts.width,
  }
end

function Terminal:init(cmd, opts)
  opts = opts or {}

  dict.merge(self, opts)

  self.cmd = cmd
  self.load_from_path = opts.load_from_path
  self.on_input = opts.on_input
  opts.load_from_path = nil
  opts.on_input = nil
  self.stopall = nil
  self.on_exit = on_exit

  return self
end

function Terminal:start(callback)
  if getpid(self.job_pid) then
    return self.job_id, self.job_pid
  end

  local scratch = Buffer.scratch()
  local cmd = self.cmd
  local id, term, pid

  Buffer.center_float(scratch)
  local winid = Buffer.winid(scratch)

  Winid.call(winid, function()
    local opts = Terminal.opts(self)

    if isempty(opts) then
      id = vim.fn.termopen(cmd)
    else
      id = vim.fn.termopen(cmd, opts)
    end

    term = Buffer(Buffer.bufnr(), true, true)
    self.job_id = id
    pid = term:get_var "terminal_job_pid"
    self.job_pid = pid

    Buffer.hide(scratch)

    local ok = getpid(pid)
    if not ok then
      error("Could not run command successfully " .. cmd)
    end

    term:autocmd({ "BufWipeout" }, function()
      self:stop()
      self:hide()

      user.terminals[id] = nil
    end)

    if callback then
      callback(self)
    end
  end)

  self.termbuf = term
  user.terminals[id] = self

  return id, pid
end

function Terminal:getpid()
  return getpid(self.job_pid)
end

function Terminal:is_running(success, failure)
  if getpid(self.job_pid) then
    if not Buffer.exists(self.termbuf) then
      killpid(self.job_pid)
      self.termbuf = false
      return false
    end

    if success then
      return success(self)
    end

    return self
  end

  if failure then
    return failure(self)
  end
end

function Terminal:unless_running(success, failure)
  return self:is_running(failure, success)
end

function Terminal:if_running(callback)
  return self:is_running(callback)
end

function Terminal:center_float(opts)
  return Terminal.float(
    self,
    dict.merge({ center = { 0.8, 0.8 } }, opts or {})
  )
end

function Terminal:dock(opts)
  return Terminal.float(
    self,
    dict.merge({ dock = 0.3 }, opts or {})
  )
end

function Terminal:send_node_at_cursor(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  local pos = Buffer.pos(src_bufnr)
  local line, col = pos.row, pos.col
  line = line - 1
  col = col - 1

  Terminal.send(self, Buffer.get_node(src_bufnr, line, col))
end

function Terminal:send_current_line(src_bufnr)
  if not self:is_running() then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return vim.api.nvim_buf_call(src_bufnr, function()
    local s = vim.fn.getline "."
    return Terminal.send(self, s)
  end)
end

function Terminal:send_buffer(src_bufnr)
  if not self:is_running() then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return Terminal.send(
    self,
    vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false)
  )
end

function Terminal:send_till_cursor(src_bufnr)
  if not self:is_running() then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return Buffer.call(src_bufnr, function()
    local line = vim.fn.line "."
    return Terminal.send(
      self,
      vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false)
    )
  end)
end

function Terminal.send_textsubject_at_cursor(
  self,
  src_bufnr
)
  if not self:is_running() then
    return
  end

  src_bufnr = src_bufnr or Buffer.bufnr()

  return Terminal.send(
    self,
    Buffer.call(src_bufnr, function()
      vim.cmd "normal! v."
      return Buffer.range_text(src_bufnr)
    end)
  )
end

function Terminal:send_range(src_bufnr)
  if not self:is_running() then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  local out = Buffer.range_text(src_bufnr)
  if not out then
    return false
  end

  return Terminal.send(self, out)
end

function Terminal:terminate_input()
  if not self:is_running() then
    return
  end
  return Terminal.send(
    self,
    vim.api.nvim_replace_termcodes(
      "<C-c>",
      true,
      false,
      true
    )
  )
end

function Terminal:send(s)
  if not self:is_running() then
    return
  end

  local id = self.job_id

  local function send_string(s)
    s = tolist(s)
    s[#s + 1] = ""

    vim.api.nvim_chan_send(id, table.concat(s, "\n"))

    self.termbuf:call(function()
      vim.cmd "normal! G"
    end)
  end

  if isa.string(s) then
    s = vim.split(s, "[\n\r]+")
  end

  if s[#s] ~= "" then
    s[#s + 1] = ""
  end

  if self.load_from_path then
    if self.on_input then
      s = self.on_input(s)
    end

    send_string(
      self.load_from_path(
        "/tmp/nvim_repl_last_input",
        function(fname)
          Path.write(fname, join(s, "\n"))
        end
      )
    )
  elseif self.on_input then
    send_string(self.on_input(s))
  else
    send_string(s)
  end

  return true
end

function Terminal:split(direction, opts)
  if not getpid(self.job_pid) then
    return
  end

  if not self:is_visible() then
    self.termbuf:split(direction, opts)
  end
end

function Terminal:float(opts)
  if not self:is_running() then
    return
  end

  if not self:is_visible() and self.termbuf then
    return self.termbuf:float(opts)
  end
end

function Terminal:hide()
  if self.termbuf then
    Buffer.hide(self.termbuf)
  end
end

function Terminal:stop()
  self:hide()

  if not self.job_pid then
    return false
  elseif not self:is_running() then
    return false
  else
    killpid(self.job_pid, 9)

    self.job_pid = false
    self.job_id = false
  end

  return true
end

function Terminal:is_visible()
  if self.termbuf then
    return self.termbuf:is_visible()
  end
  return false
end

function Terminal.stopall()
  list.each(values(user.terminals), Terminal.stop)
end

function Terminal:tabnew(opts)
  return self:split("tabnew", opts)
end

function Terminal:vsplit(opts)
  return self:split("vsplit", opts)
end

function Terminal:reset()
  return Terminal(self.cmd, self.opts)
end
