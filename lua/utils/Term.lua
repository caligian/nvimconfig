require 'utils.buffers'

local Term = Class.new 'Term'
user.term = user.term or { ID = {}, timeout = 30 }
Term.timeout = user.term.timeout
local exception = Exception "TermException"
Term.exception = exception

exception:set {
  invalid_command = "expected valid command",
  not_executable = "shell not executable",
  exited_with_error = "command exited with error",
  interrupted = "interrupted",
  invalid_id = "valid id expected",
  unknown = "unknown error",
}

local function get_status(id)
  if id == 0 then
    return false, "invalid_command"
  elseif id == -1 then
    return false, "not_executable"
  end

  local status = vim.fn.jobwait({ id }, Term.timeout)[1]
  if status ~= -1 and status ~= 0 then
    if status >= 126 then
      return false, "invalid_command"
    elseif status == -2 then
      return false, "interrupted"
    elseif status == -3 then
      return false, "invalid_id"
    end
  end

  return true
end

local function start_term(cmd, opts)
  local scratch = vim.api.nvim_create_buf(false, true)
  local id, term

  vim.api.nvim_buf_call(scratch, function()
    opts = opts or {}
    id = vim.fn.termopen(cmd)
    term = vim.fn.bufnr()
    local ok, msg = get_status(id)
    if not ok then
      exception[msg]:throw(self)
    end
  end)

  return id, term
end

function Term:wait(timeout)
  if not self.id then
    return false
  end

  local status = vim.fn.jobwait({ self.id }, timeout or Term.timeout)
  return status[1]
end

function Term:get_status()
  if not self.id then
    return false
  end
  return get_status(self.id, self.command)
end

function Term:is_running(assrt)
  if not self.id then return false end
  local ok, msg = get_status(self.id, self.command)
  if not ok and assrt then
    exception[msg]:throw(self)
  elseif not ok then
    return false, msg
  end

  return true
end

function Term:start()
  if self:is_running() then return self end

  local id, term_buffer = start_term(self.command, self.opts)
  self.id = id
  self.bufnr = term_buffer
  buffer.map(term_buffer, 'n', 'q', ':hide<CR>', {})

  dict.update(user.term.ID, id, self)

  return self
end

function Term:is_visible()
  if self.bufnr then return buffer.is_visible(self.bufnr) end
  return false
end

function Term:stop()
  if not self:is_running() then
    return
  end

  self:hide()
  vim.fn.chanclose(self.id)
  self.bufnr = nil
  user.term.ID[self.id] = nil

  return self
end

function Term.stopall()
  dict.each(user.term.ID, function(obj) obj:stop() end)
end

function Term:hide()
  if self.bufnr then buffer.hide(self.bufnr) end
end

function Term:split(direction, opts)
  if not self:is_running() then return end
  if not self:is_visible() then
    buffer.split(self.bufnr, direction, opts)
  end
end

function Term:float(opts)
  if not self:is_running() then return end
  if not self:is_visible() and self.bufnr then
    buffer.float(self.bufnr, opts)
  end
end

function Term:center_float(opts)
  self:float(dict.merge({ center = { 0.8, 0.8 } }, opts or {}))
end

function Term:dock(opts)
  self:float(dict.merge({ dock = 0.3 }, opts or {}))
end

function Term:send(s)
  if not self:is_running() then return end

  local id = self.id
  if is_a.s(s) then
    s = string.split(s, "[\n\r]")
  end
  if self.on_input then
    s = self.on_input(s)
  end
  s[#s + 1] = "\n"
  return vim.api.nvim_chan_send(id, table.concat(s, "\n"))
end

function Term:send_current_line(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    self:send(vim.fn.getline ".")
  end)
end

function Term:send_buffer(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end

function Term:send_till_point(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    local line = vim.fn.line "."
    self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
  end)
end

function Term:send_visual_range(src_bufnr)
  if not self:is_running() then return end

  src_bufnr = src_bufnr or vim.fn.bufnr()
  return self:send(buffer.range(src_bufnr))
end

function Term:terminate_input()
  if not self:is_running() then return end

  return self:send(vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
end

function Term:init(cmd, opts)
  validate {
    command = { is { "string", "table" }, cmd },
    ["?opts"] = {
      { __nonexistent = true, ["?on_input"] = "callable" },
      opts,
    },
  }

  opts = opts or {}
  self.command = cmd
  self.opts = opts
  self.on_input = opts.on_input

  return self
end

return Term
