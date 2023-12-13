require "core.utils.terminal"

if not repl then
  repl = class "repl"
  repl.repls = {}

  dict.merge(repl, terminal)
end

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

  local exists = repl.exists(
    bufnr,
    opts.workspace and "workspace"
      or opts.buffer and "buffer"
      or "dir"
  )

  if exists then
    return exists
  end

  local ft = buffer.filetype(bufnr)
  if #ft == 0 then
    return
  end

  self._bufnr = bufnr
  local ftobj = filetype(ft):loadfile()
  if not ftobj then
    return
  end

  local replcmd, _opts = ftobj:command(bufnr, "repl")
  local isws = opts.workspace
  local isdir = opts.dir
  local isbuf = opts.buffer
  local isshell = opts.shell

  if _opts then
    dict.merge(opts, _opts)
  end

  self.filetype = ft
  self.type = isdir and "dir"
    or isbuf and "buffer"
    or isws and "workspace"
    or isshell and "shell"
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

  if istable(cmd) then
    self.src = cmd[2]
    cmd = cmd[1]
  end

  self.name = self.src

  if not isshell then
    repl.repls[self.name] = self
  else
    repl.repls.shell = self
  end

  return terminal.init(self, cmd, opts)
end

function repl:reset()
  return repl(self._bufnr, self.opts)
end

function repl:stop()
  terminal.stop(self)
  return self:reset()
end

function repl.main()
  repl.set_mappings()
end

function repl.set_mappings()
  local function start(tp)
    local key, desc
    if tp == "buffer" then
      key = "<localleader>rr"
      desc = "start buffer"
    elseif tp == "workspace" then
      key = "<leader>rr"
      desc = "start workspace"
    elseif tp == "shell" then
      key = "<leader>xx"
      desc = "start shell"
    else
      key = "<leader>rR"
      desc = "start dir"
    end

    kbd.map("n", key, function()
      local buf = buffer.bufnr()
      local self = repl(buf, { [tp] = true })

      if not self then
        return
      end

      if not self:running() then
        self = self:reset()
      end

      self:start()
      if self:running() then
        print(
          "started REPL for "
            .. tp
            .. " with cmd: "
            .. self.cmd
        )
      else
        tostderr(
          "could not start REPL for "
            .. tp
            .. " with cmd: "
            .. self.cmd
        )
      end
    end, desc)
  end

  local function mkkeys(action, tp, ks)
    local key, desc
    if tp == "buffer" then
      key = "<localleader>r"
      desc = action .. " buffer"
    elseif tp == "workspace" then
      key = "<leader>r"
      desc = action .. " workspace"
    elseif tp == "shell" then
      key = "<leader>x"
      desc = action .. " shell"
    else
      key = "<leader>r"
      desc = action .. " dir"
    end

    local mode = "n"
    if istable(ks) then
      mode, ks = unpack(ks)
    end

    if tp ~= "dir" then
      return mode, key .. ks, desc
    else
      return mode, key .. string.upper(ks), desc
    end
  end

  local function map(name, tp, key, callback)
    local mode, key, desc = mkkeys(name, tp, key)

    kbd.map(mode, key, function()
      local buf = buffer.current()
      local self = repl(buf, { [tp] = true })
      if self then
        callback(self)
      end
    end, { noremap = true, silent = true, desc = desc })
  end

  local function stop(tp)
    map("stop", tp, "q", function(self)
      self:stop()
    end)
  end

  local function float(tp)
    map("float", tp, "f", function(self)
      self:center_float()
    end)
  end

  local function split(tp)
    map("split", tp, "s", function(self)
      self:split()
    end)
  end

  local function vsplit(tp)
    map("vsplit", tp, "v", function(self)
      self:vsplit()
    end)
  end

  local function send_visual_range(tp)
    map("send range", tp, { "v", "e" }, function(self)
      self:send_range()
    end)
  end

  local function send_buffer(tp)
    map("send buffer", tp, "b", function(self)
      self:send_buffer()
    end)
  end

  local function send_current_line(tp)
    map("send line", tp, "e", function(self)
      self:send_current_line()
    end)
  end

  local function send_till_cursor(tp)
    map("send till cursor", tp, "m", function(self)
      self:send_till_cursor()
    end)
  end

  list.each(
    { "buffer", "workspace", "dir", "shell" },
    function(x)
      start(x)
      stop(x)
      split(x)
      vsplit(x)
      send_till_cursor(x)
      send_visual_range(x)
      send_buffer(x)
      send_current_line(x)
      float(x)
    end
  )
end
