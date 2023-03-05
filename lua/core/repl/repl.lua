local function ensure(self)
  if self.running then
    return self
  end

  self:start()
end

new 'REPL' {
  ids = {},

  is_visible = function(self)
    return self.buffer:is_visible()
  end,

  status = function(self)
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
  end,

  is_valid = function(self)
    return self:status() ~= false
  end,

  is_interrupted = function(self)
    return self:status() == "interrupted"
  end,

  stop = function(self)
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
  end,

  stopall = function()
    for _, r in pairs(REPL.ids) do
      r:stop()
    end
  end,

  _init = function(self, ft, force)
    ft = ft or vim.bo.filetype

    ass_s(ft, "filetype")

    local r = REPL.ids[ft]
    if r and not force and r.running then
      return r
    end

    self.filetype = ft
    self.command = V.get(Lang.langs, { ft, "repl" })

    assert(self.command, "No command specified for filetype " .. ft)
    ass_s(self.command, "self.command")

    return self
  end,

  start = function(self, force)
    local function start(cmd)
      ass_s(cmd, "command")

      local buf = Buffer()
      local id

      buf:setopts({
        buflisted = false,
        modified = false
      })

      buf:setwinopts({
        number = false,
      })

      buf:call(function()
        vim.cmd("term")
        id = vim.b.terminal_job_id
        vim.api.nvim_chan_send(id, cmd .. "\r")
      end)

      return id, buf
    end

    if force then
      self:stop()
    end

    if self.running then
      return self
    end

    local id, buf = start(self.command)
    self.id = id
    self.running = true
    self.buffer = buf
    buf:setvar("_repl_filetype", self.filetype)

    REPL.ids[id] = self
    REPL.ids[self.filetype] = self

    return self
  end,

  hide = function(self)
    if self.running then
      self.buffer:hide()
    end
  end,

  split = function(self, direction)
    ensure(self)

    if self:is_visible() then
      return self
    else
      self.buffer:split(direction)
    end
  end,

  send = function(self, s)
    ensure(self)

    local id = self.id
    if V.isa(s, "table") then
      s = table.concat(s, "\n")
    end
    s = s .. "\r"
    vim.api.nvim_chan_send(id, s)
  end,

  send_current_line = function(self, src_bufnr)
    src_bufnr = src_bufnr or vim.fn.bufnr()
    vim.api.nvim_buf_call(src_bufnr, function()
      self:send(vim.fn.getline("."))
    end)
  end,

  send_buffer = function(self, src_bufnr)
    src_bufnr = src_bufnr or vim.fn.bufnr()
    self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
  end,

  send_till_point = function(self, src_bufnr)
    src_bufnr = src_bufnr or vim.fn.bufnr()
    vim.api.nvim_buf_call(src_bufnr, function()
      local line = vim.fn.line(".")
      self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
    end)
  end,

  send_visual_range = function(self, src_bufnr)
    src_bufnr = src_bufnr or vim.fn.bufnr()
    return self:send(V.visualrange(src_bufnr))
  end,

  terminate_input = function(self)
    return self:send("")
  end
}
