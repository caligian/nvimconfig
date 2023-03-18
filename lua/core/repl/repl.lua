if not REPL then class "REPL" end

REPL.ids = REPL.ids or {}
REPL._scratch_id = REPL._scratch_id or 1

-- jobwait will use this as wait time
REPL.timeout = 30

local function is_invalid_command_or_exit(bufnr)
  if vim.fn.bufexists(bufnr) == 0 then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if lines[1]:match "command not found" then
    return "invalid_command"
  else
    for i = 1, #lines do
      local x = lines[i]
      if x:match "^%[Process exited" then return "exited" end
    end
  end
  return false
end

local function is_running(id, bufnr)
  local code = vim.fn.jobwait({ id }, REPL.timeout)[1]
  local invalid_or_exit = is_invalid_command_or_exit(bufnr)
  if invalid_or_exit then return false, invalid_or_exit end
  if code >= 0 or code < -1 or code >= 126 then return false end
  return true
end

local function get_obj(current, ft)
  ft = ft or vim.bo.filetype
  if ft ~= "sh" then
    local r = REPL.ids[ft][current]
    if r then
      r.running = is_running(r.id, r.connected)
      if r.running then return r end
    end
  else
    local r = REPL.ids.sh
    if r then
      r.running = is_running(r.id, r.connected)
      if r.running then return REPL.ids.sh end
    end
  end
end

function REPL:_init(is_shell)
  local ft
  if is_shell then
    ft = "sh"
  else
    ft = vim.bo.filetype
  end

  local cmd = table.get(Lang.langs, { ft, "repl" })
  validate { command = { "s", cmd } }
  self.command = cmd
  self.filetype = ft

  if ft ~= "sh" then REPL.ids[ft] = REPL.ids[ft] or {} end
  local r = get_obj(vim.fn.bufnr(), ft)
  if r then return r end

  return self
end

function REPL:is_visible() return self.buffer:is_visible() end

function REPL:stop()
  return utils.log_pcall(function()
    if not self.running then return end

    vim.fn.chanclose(self.id)

    self.running = false
    self.buffer:delete()
    self.buffer = nil
    self.ids[self.filetype] = nil

    return self
  end)
end

function REPL.stopall()
  local sh = REPL.ids.sh
  if sh then
    sh:stop()
  else
    for ft, running in pairs(REPL.ids) do
      if ft ~= "sh" then
        for _, repl in pairs(running) do
          repl:stop()
        end
      end
    end
  end
end

function REPL:start(force)
  if self.id and self.buffer then
    self.running = is_running(self.id, self.buffer.bufnr)
  end

  if self.running then
    return self
  end

  local name = "_scratch_buffer_" .. REPL._scratch_id
  REPL._scratch_id = REPL._scratch_id + 1
  local scratch = vim.fn.bufadd(name)
  local cmd = self.command

  if force then self:stop() end

  vim.api.nvim_buf_call(scratch, function()
    vim.cmd("term " .. cmd)

    local id = vim.b.terminal_job_id
    local status, msg = is_running(id, vim.fn.bufnr())
    if msg then
      if msg == "invalid_command" then
        error("Invalid command for " .. self.filetype .. ": " .. self.command)
      elseif msg == "exited" then
        error(
          "Command exited too quickly for "
            .. self.filetype
            .. ": "
            .. self.command
        )
      end
    else
      assert(status, "Check command: " .. self.command)
    end

    vim.wo.number = false
    vim.wo.relativenumber = false
    self.id = id
    self.buffer = Buffer(vim.fn.bufname(), true)
    self.buffer.var._repl_filetype = self.filetype
    self.running = true
  end)

  self.connected = vim.fn.bufnr()

  if self.filetype == "sh" then
    REPL.ids.sh = self
  else
    table.update(REPL.ids, { self.filetype, self.connected }, self)
  end

  return self
end

function REPL:hide()
  return utils.log_pcall(function()
    if self.running then self.buffer:hide() end
  end)
end

function REPL:split(direction, opts)
  self:start()

  if self:is_visible() then
    return self
  else
    self.buffer:split(direction, opts)
  end
end

function REPL:float(opts)
  self:start()
  if self:is_visible() then
    return self
  else
    self.buffer:float(opts)
  end
end

function REPL:center_float(opts)
  return utils.log_pcall(
    function() self:float(table.merge({ center = {40, 50} }, opts or {})) end
  )
end

function REPL:dock(opts)
  return utils.log_pcall(
    function() self:float(table.merge({ dock = 0.3 }, opts or {})) end
  )
end

function REPL:send(s)
  return utils.log_pcall(function()
    self:start()

    local id = self.id
    if is_a(s, "table") then s = table.concat(s, "\n") end
    s = s .. "\r"
    vim.api.nvim_chan_send(id, s)
  end)
end

function REPL:send_current_line(src_bufnr)
  return utils.log_pcall(function()
    src_bufnr = src_bufnr or vim.fn.bufnr()
    vim.api.nvim_buf_call(
      src_bufnr,
      function() self:send(vim.fn.getline ".") end
    )
  end)
end

function REPL:send_buffer(src_bufnr)
  return utils.log_pcall(function()
    src_bufnr = src_bufnr or vim.fn.bufnr()
    self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
  end)
end

function REPL:send_till_point(src_bufnr)
  return utils.log_pcall(function()
    src_bufnr = src_bufnr or vim.fn.bufnr()
    vim.api.nvim_buf_call(src_bufnr, function()
      local line = vim.fn.line "."
      self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
    end)
  end)
end

function REPL:send_visual_range(src_bufnr)
  return utils.log_pcall(function()
    src_bufnr = src_bufnr or vim.fn.bufnr()
    return self:send(utils.visualrange(src_bufnr))
  end)
end

function REPL:terminate_input()
  return self:send(vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
end
