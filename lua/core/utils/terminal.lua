require "core.utils.buffer"

terminal = terminal or class "terminal"
terminal.terminals = terminal.terminals or {}

terminal.exceptions = {
  invalid_command = "expected valid command",
  shell_not_executable = "shell not executable",
  exited_with_error = "command exited with error",
  interrupted = "terminal interrupted",
  invalid_id = "invalid job id",
  no_default_command = "no default command provided",
}

terminal.timeout = 200

function terminal.isa(x)
  return mtget(x) == "terminal"
end

function terminal:init(cmd, opts)
  if terminal.isa(cmd) then
    return cmd
  end

  opts = opts or {}

  opts = copy(opts)
  self.cmd = cmd
  self.load_from_path = opts.load_from_path
  self.on_input = opts.on_input
  opts.load_from_path = nil
  opts.on_input = nil
  self.opts = opts
  self.id = false
  self.pid = false
  self.termbuffer = false

  return self
end

function terminal:start(callback)
  if pid_exists(self.pid) then
    return self.id, self.pid
  end

  local scratch = buffer.create_empty()
  local cmd = self.cmd
  local id, term, pid

  buffer.call(scratch, function()
    opts = opts or self.opts or {}

    if isempty(opts) then
      id = vim.fn.termopen(cmd)
    else
      id = vim.fn.termopen(cmd, opts)
    end

    local has_started = buffer.lines(scratch, 0, -1)
    has_started = list.filter(has_started, function(x)
      return #x ~= 0
    end)

    while #has_started == 0 do
      vim.wait(10)
      has_started = buffer.lines(scratch, 0, -1)
      has_started = list.filter(has_started, function(x)
        return #x ~= 0
      end)
    end

    term = buffer.bufnr()
    self.id = id
    pid = buffer.var(scratch, "terminal_job_pid")
    self.pid = pid

    local ok = pid_exists(pid)
    if not ok then
      error("Could not run command successfully " .. cmd)
    end

    buffer.map(
      scratch,
      "n",
      "q",
      ":hide<CR>",
      { name = "terminal.hide_buffer" }
    )

    buffer.au(term, { "BufWipeout" }, function()
      terminal.stop(self)
      terminal.hide(self)
    end)

    if self.connected then
      buffer.au(self.connected, { "BufWipeout" }, function()
        terminal.stop(self)
      end)
    end

    if callback then
      callback(self)
    end
  end)

  self.termbuf = term
  terminal.terminals[id] = self

  return id, pid
end

function terminal:pid_exists()
  return pid_exists(self.pid)
end

function terminal:running(success, failure)
  if pid_exists(self.pid) then
    if not buffer.exists(self.termbuf) then
      kill_pid(self.pid)
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

function terminal.unless_running(self, callback)
  return terminal.running(self, nil, callback)
end

function terminal.if_running(self, callback)
  return terminal.running(self, callback)
end

function terminal.center_float(self, opts)
  return terminal.float(
    self,
    dict.merge({ center = { 0.8, 0.8 } }, opts or {})
  )
end

function terminal.dock(self, opts)
  return terminal.float(
    self,
    dict.merge({ dock = 0.3 }, opts or {})
  )
end

function terminal.send_node_at_cursor(self, src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  local pos = buffer.pos(src_bufnr)
  local line, col = pos.row, pos.col
  line = line - 1
  col = col - 1

  terminal.send(
    self,
    buffer.get_node_text_at_pos(src_bufnr, line, col)
  )
end

function terminal.send_current_line(self, src_bufnr)
  if not terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return vim.api.nvim_buf_call(src_bufnr, function()
    local s = vim.fn.getline "."
    return terminal.send(self, s)
  end)
end

function terminal.send_buffer(self, src_bufnr)
  if not terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return terminal.send(
    self,
    vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false)
  )
end

function terminal.send_till_cursor(self, src_bufnr)
  if not terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return buffer.call(src_bufnr, function()
    local line = vim.fn.line "."
    return terminal.send(
      self,
      vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false)
    )
  end)
end

function terminal.send_textsubject_at_cursor(
  self,
  src_bufnr
)
  if not terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or buffer.bufnr()

  return terminal.send(
    self,
    buffer.call(src_bufnr, function()
      vim.cmd "normal! v."
      return buffer.range_text(src_bufnr)
    end)
  )
end

function terminal.send_range(self, src_bufnr)
  if not terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  local out = buffer.range_text(src_bufnr)
  if not out then
    return false
  end

  return terminal.send(self, out)
end

function terminal.terminate_input(self)
  if not terminal.running(self) then
    return
  end
  return terminal.send(
    self,
    vim.api.nvim_replace_termcodes(
      "<C-c>",
      true,
      false,
      true
    )
  )
end

function terminal.send(self, s)
  if not terminal.running(self) then
    return
  end

  local id = self.id

  local function send_string(s)
    s = tolist(s)
    s[#s + 1] = ""

    vim.api.nvim_chan_send(id, table.concat(s, "\n"))

    buffer.call(self.termbuf, function()
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
          file.write(fname, join(s, "\n"))
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

function terminal.split(self, direction, opts)
  if not pid_exists(self.pid) then
    return
  end

  if not terminal.visible(self) then
    buffer.split(self.termbuf, direction, opts)
  end
end

function terminal.float(self, opts)
  if not terminal.running(self) then
    return
  end

  if not terminal.visible(self) and self.termbuf then
    return buffer.float(self.termbuf, opts)
  end
end

function terminal.hide(self)
  if self.termbuf then
    buffer.hide(self.termbuf)
  end
end

function terminal.stop(self)
  terminal.hide(self)

  if not self.pid then
    return false
  elseif not terminal.running(self) then
    return false
  else
    kill_pid(self.pid, 9)

    self.pid = false
    self.id = false
  end

  return true
end

function terminal.stop_deprecated(self)
  if not terminal.running(self) then
    return
  end

  terminal.hide(self)
  vim.fn.chanclose(self.id)
  self.termbuf = nil
  terminal.terminals[self.id] = false

  return self
end

function terminal.visible(self)
  if self.termbuf then
    return buffer.isvisible(self.termbuf)
  end
  return false
end

function terminal.stopall()
  list.each(values(terminal.terminals), terminal.stop)
end

function terminal:tabnew(opts)
  return self:split("tabnew", opts)
end

function terminal:vsplit(opts)
  return self:split("vsplit", opts)
end

function terminal:reset()
  return terminal(self.cmd, self.opts)
end
