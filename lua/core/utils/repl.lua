require "core.utils.terminal"

repl = repl or class "repl"
repl.repls = repl.repls or {}
dict.merge(repl, terminal)

function repl.exists(self, tp)
  assertisa(self, union("repl", "string", "number"))

  if isstring(self) then
    return repl.repls[self.name]
  elseif isnumber(self) then
    if tp == "dir" then
      return repl.repls[path.dirname(buffer.name(self))]
    elseif tp == "workspace" then
      return repl.repls[filetype.workspace(self)]
    else
      return repl.repls[buffer.name(self)]
    end
  elseif repl.isa(self) then
    return self
  end
end

function repl:init(bufnr, opts)
  if isstring(bufnr) and repl.repls[bufnr] then
    return repl.repls[bufnr]
  end

  opts = opts or {}

  if opts.shell and repl.repls.shell then
    return repl.repls.shell
  end

  bufnr = bufnr or buffer.current()
  if not buffer.exists(bufnr) then
    return
  end

  local exists =
    repl.exists(bufnr, opts.workspace and "workspace" or opts.buffer and "buffer" or "dir")
  if exists then
    return exists
  end

  local ft = buffer.filetype(bufnr)
  if #ft == 0 then
    return
  end

  self._bufnr = bufnr
  local ftobj = filetype(ft):loadfile()
  local replcmd = ftobj:command(bufnr, "repl")
  local isws = opts.workspace
  local isdir = opts.dir
  local isbuf = opts.buffer
  local isshell = opts.shell

  self.filetype = ft
  self.type = isdir and "dir" or isbuf and "buffer" or "workspace" or isshell and "shell"
  local cmd

  if isshell then
    cmd = user.shell or "/bin/bash"
  elseif isws then
    if not replcmd.workspace then
      return
    end

    cmd = replcmd.workspace
  elseif isdir then
    if not replcmd.dir then
      return
    end

    cmd = replcmd.dir
  else
    if not replcmd.buffer then
      return
    end

    cmd = replcmd.buffer
  end

  self.src = cmd[2]
  self.name = self.src

  if not isshell then
    repl.repls[self.name] = self
  else
    repl.repls.shell = self
  end

  return terminal.init(self, cmd[1], opts)
end

function repl:reset()
  return repl(self._bufnr, self.opts)
end

function repl:stop()
  terminal.stop(self)
  return self:reset()
end

function repl.set_mappings()
  local function start(tp)
    local key, desc
    if tp == "buffer" then
      key = "<localleader>--"
      desc = "start buffer"
    elseif tp == "workspace" then
      key = "<leader>rr"
      desc = "start workspace"
    else
      key = "<leader>rR"
      desc = "start dir"
    end

    kbd.map("n", key, function()
      local buf = buffer.bufnr()
      local self = repl(buf, { [tp] = true })

      if not self:running() then
        self = self:reset()
      end

      self:start()
      self:split()
    end, desc)
  end

  local function mkkeys(action, tp, ks)
    local key, desc
    if tp == "buffer" then
      key = "<localleader>-"
      desc = action .. " buffer"
    elseif tp == "workspace" then
      key = "<leader>r"
      desc = action .. " workspace"
    else
      key = "<leader>r"
      desc = action .. " dir"
    end

    if tp ~= "dir" then
      return key .. ks, desc
    else
      return key .. string.upper(ks), desc
    end
  end

  local function stop(tp)
    local key, desc = mkkeys("stop", tp, "q")
    kbd.map("n", key, function()
      local buf = buffer.current()
      local self = repl(buf, { [tp] = true })

      if self and self:running() then
        self:stop()
      end
    end, desc)
  end

  list.each({ "buffer", "workspace", "dir" }, function(x)
    start(x)
    stop(x)
    -- split(x)
    -- vsplit(x)
    -- send(x)
  end)
end

repl.set_mappings()

-- x = repl(buffer.current(), {buffer = true})
-- x:start()
-- x:split()
-- x:hide()
