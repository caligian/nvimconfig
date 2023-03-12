class "REPL"

REPL.ids = REPL.ids or {}

function REPL._init(self, ft, force)
  ft = ft or vim.bo.filetype

  validate {
    filetype = { "s", ft },
  }

  local r = REPL.ids[ft]
  if r and not force and r.running then
    return r
  end

  self.filetype = ft
  self.command = get(Lang.langs, { ft, "repl" })

  validate { command = { "s", self.command } }
end

function REPL.is_visible(self)
  return self.buffer:is_visible()
end

function REPL.ensure(self)
  if self.running then
    return self
  end

  self:start()
end

function REPL.status(self)
  if not self.id then
    return false
  end

  local id = self.id
  id = vim.fn.jobwait({ id }, 0)[1]

  if id == -1 then
    return true
  elseif id == -2 then
    return "interrupted"
  else
    return false
  end
end

function REPL.is_valid(self)
  return self:status() ~= false
end

function REPL.is_interrupted(self)
  return self:status() == "interrupted"
end

function REPL.stop(self)
  if not self.running then
    return
  end

  vim.fn.chanclose(self.id)

  self.running = false
  self.buffer:delete()
  self.buffer = nil
  self.ids[self.id] = nil
  self.ids[self.filetype] = nil

  return self
end

function REPL.stopall()
  for _, r in pairs(REPL.ids) do
    r:stop()
  end
end

function REPL.start(self, force)
  if self.running then
    return self
  end

  local buf = Buffer()
  local id
  local cmd = self.command

  buf:setopts {
    buflisted = false,
    modified = false,
  }

  buf:setwinopts {
    number = false,
  }

  buf:call(function()
    vim.cmd "term"
    id = vim.b.terminal_job_id
    vim.api.nvim_chan_send(id, cmd .. "\r")
  end)

  if force then
    self:stop()
  end

  self.id = id
  self.running = true
  self.buffer = buf
  buf.wo.number = false
  buf.var._repl_filetype = self.filetype

  REPL.ids[id] = self
  REPL.ids[self.filetype] = self

  return self
end

function REPL.hide(self)
  if self.running then
    self.buffer:hide()
  end
end

function REPL.split(self, direction, opts)
  self:ensure()

  if self:is_visible() then
    return self
  else
    self.buffer:split(direction, opts)
  end
end

function REPL.float(self, opts)
  self:ensure()
  if self:is_visible() then
    return self
  else
    self.buffer:float(opts)
  end
end

function REPL.center_float(self, opts)
  self:float(merge({center=true}, opts or {}))
end

function REPL.dock(self, opts)
  self:float(merge({dock=0.3}, opts or {}))
end

function REPL.send(self, s)
  self:ensure()

  local id = self.id
  if is_a(s, "table") then
    s = table.concat(s, "\n")
  end
  s = s .. "\r"
  vim.api.nvim_chan_send(id, s)
end

function REPL.send_current_line(self, src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    self:send(vim.fn.getline ".")
  end)
end

function REPL.send_buffer(self, src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end

function REPL.send_till_point(self, src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    local line = vim.fn.line "."
    self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
  end)
end

function REPL.send_visual_range(self, src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  return self:send(visualrange(src_bufnr))
end

function REPL.terminate_input(self)
  return self:send ""
end
