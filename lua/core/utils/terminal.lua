require "core.utils.buffer"

Terminal = Terminal or class "Terminal"
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

function Terminal:init(cmd, opts)
  if Terminal.isa(cmd) then
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

function Terminal:start(callback)
  if getpid(self.pid) then
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

    local ok = getpid(pid)
    if not ok then
      error("Could not run command successfully " .. cmd)
    end

    buffer.set_option(term, "bufhidden", "hide")

    buffer.map(
      scratch,
      "n",
      "q",
      ":hide<CR>",
      { name = "Terminal.hide_buffer" }
    )

    buffer.Autocmd(term, { "BufWipeout" }, function()
      Terminal.stop(self)
      Terminal.hide(self)
    end)

    if self.connected then
      buffer.Autocmd(
        self.connected,
        { "BufWipeout" },
        function()
          Terminal.stop(self)
        end
      )
    end

    if callback then
      callback(self)
    end
  end)

  self.termbuf = term
  user.terminals[id] = self

  return id, pid
end

function Terminal:getpid()
  return getpid(self.pid)
end

function Terminal:running(success, failure)
  if getpid(self.pid) then
    if not buffer.exists(self.termbuf) then
      killpid(self.pid)
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

function Terminal.unless_running(self, callback)
  return Terminal.running(self, nil, callback)
end

function Terminal.if_running(self, callback)
  return Terminal.running(self, callback)
end

function Terminal.center_float(self, opts)
  return Terminal.float(
    self,
    dict.merge({ center = { 0.8, 0.8 } }, opts or {})
  )
end

function Terminal.dock(self, opts)
  return Terminal.float(
    self,
    dict.merge({ dock = 0.3 }, opts or {})
  )
end

function Terminal.send_node_at_cursor(self, src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  local pos = buffer.pos(src_bufnr)
  local line, col = pos.row, pos.col
  line = line - 1
  col = col - 1

  Terminal.send(
    self,
    buffer.get_node_text_at_pos(src_bufnr, line, col)
  )
end

function Terminal.send_current_line(self, src_bufnr)
  if not Terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return vim.api.nvim_buf_call(src_bufnr, function()
    local s = vim.fn.getline "."
    return Terminal.send(self, s)
  end)
end

function Terminal.send_buffer(self, src_bufnr)
  if not Terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return Terminal.send(
    self,
    vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false)
  )
end

function Terminal.send_till_cursor(self, src_bufnr)
  if not Terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return buffer.call(src_bufnr, function()
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
  if not Terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or buffer.bufnr()

  return Terminal.send(
    self,
    buffer.call(src_bufnr, function()
      vim.cmd "normal! v."
      return buffer.range_text(src_bufnr)
    end)
  )
end

function Terminal.send_range(self, src_bufnr)
  if not Terminal.running(self) then
    return
  end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  local out = buffer.range_text(src_bufnr)
  if not out then
    return false
  end

  return Terminal.send(self, out)
end

function Terminal.terminate_input(self)
  if not Terminal.running(self) then
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

function Terminal.send(self, s)
  if not Terminal.running(self) then
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

function Terminal.split(self, direction, opts)
  if not getpid(self.pid) then
    return
  end

  if not Terminal.visible(self) then
    buffer.split(self.termbuf, direction, opts)
  end
end

function Terminal.float(self, opts)
  if not Terminal.running(self) then
    return
  end

  if not Terminal.visible(self) and self.termbuf then
    return buffer.float(self.termbuf, opts)
  end
end

function Terminal.hide(self)
  if self.termbuf then
    buffer.hide(self.termbuf)
  end
end

function Terminal.stop(self)
  Terminal.hide(self)

  if not self.pid then
    return false
  elseif not Terminal.running(self) then
    return false
  else
    killpid(self.pid, 9)

    self.pid = false
    self.id = false
  end

  return true
end

function Terminal.stop_deprecated(self)
  if not Terminal.running(self) then
    return
  end

  Terminal.hide(self)
  vim.fn.chanclose(self.id)
  self.termbuf = nil
  user.terminals[self.id] = false

  return self
end

function Terminal.visible(self)
  if self.termbuf then
    return buffer.isvisible(self.termbuf)
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
