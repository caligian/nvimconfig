require 'core.utils.buffer'

terminal = {
  terminals = {}, 
  timeout = 30,
  exception = {
    invalid_command = exception "expected valid command",
    shell_not_executable = exception "shell not executable",
    exited_with_error =  exception "command exited with error",
    interrupted = exception "terminal interrupted",
    invalid_id = exception  "invalid job id",
  }
}

function terminal.new(cmd, opts)
  opts = vim.deepcopy(opts or {})

  validate {
    cmd = {'string', cmd},
    opts = {'table', opts}
  }

  local on_input = opts.on_input
  opts.on_input = nil

  return {
    id = false,
    cmd = cmd,
    opts = opts,
    on_input = on_input or false,
    center_float = function (self, opts)
      return self:float(dict.merge({ center = { 0.8, 0.8 } }, opts or {}))
    end,
    dock = function (self, opts)
      return self:float(dict.merge({ dock = 0.3 }, opts or {}))
    end,
    send_node_at_cursor = function (self, src_bufnr)
      src_bufnr = src_bufnr or vim.fn.bufnr()
      local pos = buffer.pos(src_bufnr)
      local line, col = pos.row, pos.col
      line = line - 1
      col = col - 1

      self:send(buffer.get_node_text_at_pos(src_bufnr, line, col))
    end,
    send_current_line = function (self, src_bufnr)
      if not self:isrunning() then return end

      src_bufnr = src_bufnr or vim.fn.bufnr()
      return vim.api.nvim_buf_call(src_bufnr, function()
        local s = vim.fn.getline "."
        return self:send(s)
      end)
    end,
    send_buffer = function (self, src_bufnr)
      if not self:isrunning() then return end

      src_bufnr = src_bufnr or vim.fn.bufnr()
      return self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, -1, false))
    end,
    send_till_cursor = function (self, src_bufnr)
      if not self:isrunning() then return end

      src_bufnr = src_bufnr or vim.fn.bufnr()
      return buffer.call(src_bufnr, function()
        local line = vim.fn.line "."
        return self:send(vim.api.nvim_buf_get_lines(src_bufnr, 0, line, false))
      end)
    end,
    send_textsubject_at_cursor = function (self, src_bufnr)
      if not self:isrunning() then return end
      src_bufnr = src_bufnr or buffer.bufnr()

      return self:send(buffer.call(src_bufnr, function()
        vim.cmd "normal! v."
        return buffer.rangetext(src_bufnr)
      end))
    end,
    send_range = function (self, src_bufnr)
      if not self:isrunning() then return end
      src_bufnr = src_bufnr or vim.fn.bufnr()
      return self:send(buffer.rangetext(src_bufnr))
    end,
    terminate_input = function (self)
      if not self:isrunning() then return end
      return self:send(vim.api.nvim_replace_termcodes("<C-c>", true, false, true))
    end,
    send = function (self, s)
      if not self:isrunning() then return end

      local id = self.id
      if is_a.string(s) then s = vim.split(s, "[\n\r]+") end
      if self.on_input then s = self.on_input(s) end

      s[#s + 1] = "\n"
      s = array.map(s, string.trim)

      return vim.api.nvim_chan_send(id, table.concat(s, "\n"))
    end,
    split = function (self)
      if not self:is_running() then return end
      if not self:is_visible() then buffer.split(self.bufnr, direction, opts) end
    end,
    float = function (self)
      if not self:is_running() then return end
      if not self:is_visible() and self.bufnr then return buffer.float(self.bufnr, opts) end
    end,
    hide = function (self)
      if self.bufnr then buffer.hide(self.bufnr) end
    end,
    stop = function (self)
      if not self:is_running() then return end

      self:hide()
      vim.fn.chanclose(self.id)
      self.bufnr = nil
      terminal.terminals[self.id] = false

      return self
    end,
    is_visible = function (self)
      if self.bufnr then return buffer.isvisible(self.bufnr) end
      return false
    end,
    start = function (self)
      local scratch = buffer.create_empty()
      local id, term

      buffer.call(scratch, function()
        opts = opts or {}

        if dict.isblank(self.opts) then
          id = vim.fn.termopen(cmd)
        else
          id = vim.fn.termopen(cmd, self.opts)
        end

        term = buffer.bufnr()

        buffer.map(term, 'n', 'q', ':hide<CR>', {})

        local ok, ex = self:get_status(opts.timeout or terminal.timeout)
        if not ok and ex then ex:throw() end
      end)

      self.id = id
      self.bufnr = term
      terminal.terminals[id] = self

      return id
    end,
    get_status = function (self, timeout)
      if not self.id then return end

      local id = self.id
      if id == 0 then
        return false, terminal.exception.invalid_command
      elseif id == -1 then
        return false, terminal.exception.shell_not_executable
      end

      local status = vim.fn.jobwait({id}, timeout or terminal.timeout)[1]
      if status ~= -1 and status ~= 0 then
        if status >= 126 then
          return false, terminal.exception.invalid_command 
        elseif status == -2 then
          return false, terminal.exception.interrupted
        elseif status == -3 then
          return false, terminal.exception.invalid_id
        end
      end

      return true
    end,
    is_running = function (self)
      return (self:get_status())
    end
  }
end

function terminal.stop_all()
  dict.each(terminal.terminals, function (_, obj)
    if obj:is_running() then obj:stop() end
  end)
end