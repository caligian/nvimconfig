local function get_filetype(args)
  local ft = args.args
  if #ft == 0 then
    ft = vim.bo.filetype
    if #ft == 0 then
      ft = vim.api.nvim_buf_get_var(vim.fn.bufnr(), "_repl_filetype") or ""
    end
  end

  if #ft == 0 then
    return false
  else
    return ft
  end
end

local function wrap(f)
  return function(args)
    local ft = get_filetype(args)
    if ft then
      local r = REPL(ft)
      r:start()
      if f then
        return f(r)
      end
    end
  end
end

local function stop(args)
  local ft = get_filetype(args)
  if ft then
    local r = REPL(ft)
    r:stop()
  end
end

V.command(
  "StartREPL",
  wrap(function(r)
    r:split("s")
  end),
  { nargs = "?" }
)

V.command(
  "TerminateInputREPL",
  wrap(function(r)
    r:terminate_input()
  end),
  { nargs = "?" }
)

V.command("StopREPL", stop, { nargs = "?" })

V.command(
  "SplitREPL",
  wrap(function(r)
    r:split("s")
  end),
  { nargs = "?" }
)

V.command(
  "VsplitREPL",
  wrap(function(r)
    r:split("v")
  end),
  { nargs = "?" }
)

V.command(
  "HideREPL",
  wrap(function(r)
    r:hide()
  end),
  { nargs = "?" }
)

V.command(
  "SendREPL",
  wrap(function(r)
    r:send(vim.fn.input("Send string > "))
  end),
  { nargs = "?" }
)

V.command(
  "SendLineREPL",
  wrap(function(r)
    r:send_current_line()
  end),
  { nargs = "?" }
)

V.command(
  "SendBufferREPL",
  wrap(function(r)
    r:send_buffer()
  end),
  { nargs = "?" }
)

V.command(
  "SendTillPointREPL",
  wrap(function(r)
    r:send_till_point()
  end),
  { nargs = "?" }
)

V.command(
  "SendRangeREPL",
  wrap(function(r)
    r:send_visual_range()
  end),
  { nargs = "?" }
)
