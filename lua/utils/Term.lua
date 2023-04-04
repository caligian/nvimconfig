if not Term then
  class "Term"
end

Term.ids = Term.ids or {}
Term.timeout = 30

local function get_status(id, cmd)
  if id == 0 then
    return {
      success = false,
      reason = "invalid_command",
      cmd = cmd,
    }
  elseif id == -1 then
    return {
      success = false,
      reason = "shell_not_executable",
      cmd = cmd,
    }
  end

  local status = vim.fn.jobwait({ id }, Term.timeout)[1]
  if status ~= -1 and status ~= 0 then
    if status >= 126 then
      return {
        success = false,
        reason = "invalid_command",
        job_id = id,
        cmd = cmd,
      }
    elseif status >= 1 then
      return {
        success = false,
        reason = "exited_with_error",
        job_id = id,
        cmd = cmd,
      }
    elseif status == -2 then
      return {
        success = false,
        reason = "interrupted",
        job_id = id,
        cmd = cmd,
      }
    elseif status == -3 then
      return {
        success = false,
        reason = "invalid_id",
        job_id = id,
        cmd = cmd,
      }
    else
      return {
        success = false,
        reason = "unknown",
        job_id = id,
        cmd = cmd,
      }
    end
  end

  return { success = true, cmd = cmd, job_id = id }
end

local function start_term(cmd, opts)
  local scratch = vim.api.nvim_create_buf(false, true)
  local id, term

  vim.api.nvim_buf_call(scratch, function()
    opts = opts or {}
    id = vim.fn.termopen(cmd)
    term = vim.fn.bufnr()
    local status = get_status(id, cmd)
    if not status.success then
      throw_error(status)
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

function Term:is_running()
  if not self.id then
    return false
  end

  local status = get_status(self.id, self.command)
  if not status.success then
    return false, status
  end

  return true
end

function Term:start()
  if self:is_running() then
    return self
  end

  local id, term_buffer = start_term(self.command, self.opts)
  self.id = id
  self.buffer = Buffer(term_buffer, true)

  table.update(Term.ids, id, self)

  return self
end

function Term:is_visible()
  if self.buffer then
    return self.buffer:is_visible()
  end
  return false
end

function Term:stop()
  if not self:is_running() then
    return
  end

  vim.fn.chanclose(self.id)

  self.buffer:delete()
  self.buffer = nil
  self.ids[self.id] = nil

  return self
end

function Term.stopall()
  table.teach(Term.ids, function(id, _)
    if is_a.n(id) then
      vim.fn.chanclose(id)
    end
  end)
end

function Term:hide()
  if self:is_running() then
    self.buffer:hide()
  end
end

function Term:split(direction, opts)
  if not self:is_visible() then
    self.buffer:split(direction, opts)
  end
end

function Term:float(opts)
  if not self:is_visible() then
    self.buffer:float(opts)
  end
end

function Term:center_float(opts)
  self:float(table.merge({ center = { 0.8, 0.8 } }, opts or {}))
end

function Term:dock(opts)
  self:float(table.merge({ dock = 0.3 }, opts or {}))
end

function Term:send(s)
  local id = self.id
  if is_a.s(s) then
    s = string.split(s, "[\n\r]")
  end
  if self.on_input then
    s = self.on_input(s)
  end
  s[#s + 1] = "\n"
  vim.api.nvim_chan_send(id, table.concat(s, "\n"))
end

function Term:send_current_line(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    self:send(vim.fn.getline ".")
  end)
end

function Term:send_buffer(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
end

function Term:send_till_point(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  vim.api.nvim_buf_call(src_bufnr, function()
    local line = vim.fn.line "."
    self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
  end)
end

function Term:send_visual_range(src_bufnr)
  src_bufnr = src_bufnr or vim.fn.bufnr()
  return self:send(utils.visualrange(src_bufnr))
end

function Term:terminate_input()
  return self:send(vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
end

function Term:init(cmd, opts)
  validate {
    command = { is { "s", "t" }, cmd },
    ["?opts"] = {
      { __nonexistent = true, ["?on_input"] = "f" },
      opts,
    },
  }

  opts = opts or {}
  self.command = cmd
  self.opts = opts
  self.on_input = opts.on_input

  return self
end
