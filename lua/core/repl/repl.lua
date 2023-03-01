class("REPL")

REPL.ids = REPL.ids or {}

function REPL:is_visible()
  return self.buffer:is_visible()
end

function REPL:status()
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

function REPL:is_valid()
  return self:status() ~= false
end

function REPL:is_running()
  return self:status()
end

function REPL:is_interrupted()
  return self:status() == "interrupted"
end

function REPL:stop()
  if not self:is_running() then
    return
  end

  vim.fn.chanclose(self.id)

  self.running = false
  self.id = nil
  self:hide()
  self.buffer:delete()
  self.buffer = nil
end

function REPL:stopall()
  for _, r in pairs(REPL.ids) do
    r:stop()
  end
end

function REPL:_init(ft, force)
  ft = ft or vim.bo.filetype
  V.asss(ft)

  local r = REPL.ids[ft]
  if r and not force and r:is_running() then
    return r
  end

  self.filetype = ft
  self.command = V.get(Lang.langs, { ft, "repl" })

  assert(self.command, "No command specified for filetype " .. ft)
  V.asss(self.command)

  return self
end

local function start(cmd)
  local buf = Buffer()
  local id

  buf:call(function()
    vim.cmd("term")
    id = vim.b.terminal_job_id
    vim.bo.buflisted = false
    vim.wo.number = false
    vim.bo.modified = true
    vim.api.nvim_chan_send(id, cmd .. "\r")
  end)

  return id, buf
end

function REPL:start(force)
  if force or not self:is_running() then
    self:stop()
    start(self.command)
  end

  if self:is_running() then
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
end

function REPL:hide()
  if self:is_running() then
    self.buffer:hide()
  end
end

local function ensure(self)
  if self:is_running() then
    return self
  end

  self:start()
end

function REPL:split(direction)
  ensure(self)

  if self:is_visible() then
    return self
  else
    self.buffer:split(direction)
  end
end

function REPL:send(s)
  ensure(self)

  local id = self.id
  if V.isa(s, "table") then
    s = table.concat(s, "\n")
  end
  s = s .. "\r"
  vim.api.nvim_chan_send(id, s)
end

function REPL:send_current_line(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    self:send(vim.fn.getline("."))
  end)
end

function REPL:send_buffer(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end

function REPL:send_till_point(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    local line = vim.fn.line(".")
    self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
  end)
end

function REPL:send_visual_range(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  return self:send(V.visualrange(src_bufnr))
end

function REPL:terminate_input()
  return self:send("")
end
