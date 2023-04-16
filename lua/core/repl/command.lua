local command = utils.command

local function wrap(f, is_shell, start)
  return function(args)
    local ft = args.args

    if is_shell then
      ft = "sh"
    elseif #ft == 0 then
      ft = vim.bo.filetype
    end

    local r = REPL.create(ft, vim.fn.bufnr())
    if r then
      if start then r:start() end
      f(r)
    end
  end
end

local function get_builtin()
  return array.grep(dict.keys(Lang.langs), function(ft)
    if Lang.langs[ft].repl then
      return true
    end
    return false
  end)
end

command(
  "REPLStart",
  wrap(function(r)
    r:split("s", { resize = 0.3, min = 0.1 })
  end, false, true),
  { nargs = "?", complete = get_builtin }
)

command(
  "REPLTerminateInput",
  wrap(function(r)
    r:terminate_input()
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLStop",
  wrap(function(r)
    r:stop()
  end, false),
  { complete = get_builtin, nargs = "?" }
)

command(
  'REPLStopAll',
  REPL.stopall,
  {}
)

command(
  "REPLFloatEditor",
  wrap(function(r)
    r:center_float { relative = "editor" }
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLFloat",
  wrap(function(r)
    r:center_float { relative = "win" }
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSplit",
  wrap(function(r)
    r:split("s", { resize = 0.3, min = 0.1 }, false, true)
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLVsplit",
  wrap(function(r)
    r:split("v", { resize = 0.3, min = 0.1 }, false, true)
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLDock",
  wrap(function(r)
    r:dock { relative = "win" }
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLHide",
  wrap(function(r)
    r:hide()
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSend",
  wrap(function(r)
    r:send(vim.fn.input "To REPL > ")
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendLine",
  wrap(function(r)
    r:send_current_line()
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendBuffer",
  wrap(function(r)
    r:send_buffer()
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendTillPoint",
  wrap(function(r)
    r:send_till_point()
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendRange",
  wrap(function(r)
    r:send_visual_range()
  end, false, true),
  { complete = get_builtin, nargs = "?" }
)

-- Shell
command(
  "ShellStart",
  wrap(function(r)
    r:split("s", { resize = 0.3, min = 10, full = true })
  end, true, true),
  {}
)

command(
  "ShellTerminateInput",
  wrap(function(r)
    r:terminate_input()
  end, true),
  {}
)

command(
  "ShellStop",
  wrap(function(r)
    r:stop()
  end, true),
  {}
)

command(
  "ShellSplit",
  wrap(function(r)
    r:split("s", { resize = 0.3, min = 0.1, full = true })
  end, true, true),
  {}
)

command(
  "ShellVsplit",
  wrap(function(r)
    r:split("v", { resize = 0.3, min = 0.1, full = true })
  end, true, true),
  {}
)

command(
  "ShellDock",
  wrap(function(r)
    r:dock {}
  end, true, true),
  {}
)

command(
  "ShellHide",
  wrap(function(r)
    r:hide()
  end, true, true),
  {}
)

command(
  "ShellSend",
  wrap(function(r)
    r:send(vim.fn.input "To shell > ")
  end, true, true),
  {}
)

command(
  "ShellSendLine",
  wrap(function(r)
    r:send_current_line()
  end, true, true),
  {}
)

command(
  "ShellSendBuffer",
  wrap(function(r)
    r:send_buffer()
  end, true, true),
  {}
)

command(
  "ShellSendTillPoint",
  wrap(function(r)
    r:send_till_point()
  end, true, true),
  {}
)

command(
  "ShellFloatEditor",
  wrap(function(r)
    r:center_float { relative = "editor" }
  end, true, true),
  {}
)

command(
  "ShellFloat",
  wrap(function(r)
    r:center_float { relative = "win" }
  end, true, true),
  {}
)

command(
  "ShellSendRange",
  wrap(function(r)
    r:send_visual_range()
  end, true, true),
  {}
)
