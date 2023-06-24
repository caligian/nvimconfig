require 'core.utils.terminal'

repl = {
  repls = {},
  exception = {
  }
}

function repl.new(ft, cmd)
  ft = ft or vim.bo.filetype
  if #ft == 0 then return end

  local exists = repl.repls[ft]
  if exists then return exists end

  repl.repls[ft] = {
    default_cmd = cmd,
    ft = ft,
    buffers = {},
    single_instance = false,
    terminals = {},
    start_single = function (self, cmd, opts)
      if self.single_instance and self.single_instance:is_running() then return self.single_instance end

      cmd = self.cmd
      local term = terminal.new(cmd, opts)
      self.single_instance = term

      return term:start()
    end,
    start = function (self, cmd, opts)
      local bufnr = buffer.bufnr() or opts.bufnr
      local exists = self.buffers[bufnr]
      if exists and exists:is_running() then return exists end

      if not cmd and not self.default_cmd then
        cmd = filetype.get(self.ft, 'repl')

        if not cmd then 
          return 
        elseif is_a.table(cmd) then
          local tmp = cmd
          cmd = tmp[1]
          tmp[1] = nil

          if not opts then
            opts = tmp 
          else
            opts = dict.merge(deepcopy(opts), tmp)
          end
        end
      end

      opts = opts or {}
      local term = terminal.new(cmd, opts)
      term:start()
      self.buffers[bufnr] = term
      self.terminals[cmd] = term

      return term
    end,
    stop = function (self, cmd)
      if not cmd then
        if self.single_instance then
          return self.single_instance:stop()
        end
      elseif self.terminals[cmd] then
        return self.terminals[cmd]:stop()
      end
    end,
    stop_all = function (self)
      local single_running = self.single_instance:is_running()
      if single_running then self.single_instance:stop() end

      dict.each(self.terminals, function (_, obj) obj:stop() end)

      self.single_instance = false
      self.terminals = false

      return self
    end,
    unless_running = function (self, cmd, callback)
      if is_a.callable(cmd) then
        return self.single_instance:if_running(callback)
      elseif not self.terminals[cmd] then
        return
      else
        self.terminals[cmd]:if_running(callback)
      end
    end,
    if_running = function (self, cmd, callback)
      if is_a.callable(cmd) then
        return self.single_instance:if_running(callback)
      elseif not self.terminals[cmd] then
        return
      else
        self.terminals[cmd]:if_running(callback)
      end
    end
  }

  return repl.repls[ft]
end

r = repl.new('lua', 'lua')
-- r:start_single()
-- r.single_instance:dock({dock=0.3})
r:start('ls')
r.terminals.ls:split()
pp(r)
