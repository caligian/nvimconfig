local command = utils.command

local function get_repl(ft)
  if not table.contains(Lang.langs, ft, "repl") then return end
  local current = vim.fn.bufnr()
  local exists = table.contains(REPL.ids, ft, current)
  if exists then return exists end

  local r = REPL(ft)
  return r
end

local function wrap(f, is_shell, start)
  return function(args)
    local ft = args.args
    if is_shell then
      ft = 'sh'
    elseif #ft == 0 then
      ft = vim.bo.filetype
    end
    local r = get_repl(ft)
    if r then
      if start then r:start() end
      f(r)
    end
  end
end



command(
  "REPLStart",
  wrap(function(r) r:split("s", { resize = 0.3, min = 0.1 }) end, false, true),
  {nargs=1}
)

command("REPLTerminateInput", wrap(function(r) r:terminate_input() end, false, true), {})

command("REPLStop", wrap(function(r) r:stop() end, false), {})

command(
  "REPLSplit",
  wrap(function(r) r:split("s", { resize = 0.3, min = 0.1 }, false, true) end),
  {}
)

command(
  "REPLVsplit",
  wrap(function(r) r:split("v", { resize = 0.3, min = 0.1 }, false, true) end),
  {}
)

command("REPLDock", wrap(function(r) r:dock { relative = "win" } end, false, true), {})

command("REPLHide", wrap(function(r) r:hide() end, false, true), {})

command("REPLSend", wrap(function(r) r:send(vim.fn.input "To REPL > ") end, false, true), {})

command("REPLSendLine", wrap(function(r) r:send_current_line() end, false, true), {})

command("REPLSendBuffer", wrap(function(r) r:send_buffer() end, false, true), {})

command("REPLSendTillPoint", wrap(function(r) r:send_till_point() end, false, true), {})

command("REPLSendRange", wrap(function(r) r:send_visual_range() end, false, true), {})

-- Shell
command(
  "ShellStart",
  wrap(
    function(r) r:split("s", { resize = 0.3, min = 10, full = true }) end,
    true,
    true
  ),
  {}
)

command(
  "ShellTerminateInput",
  wrap(function(r) r:terminate_input() end, true),
  {}
)

command("ShellStop", wrap(function(r) r:stop() end, true), {})

command(
  "ShellSplit",
  wrap(
    function(r) r:split("s", { resize = 0.3, min = 0.1, full = true }) end,
    true,
    true
  ),
  {}
)

command(
  "ShellVsplit",
  wrap(
    function(r) r:split("v", { resize = 0.3, min = 0.1, full = true }) end,
    true, true
  ),
  {}
)

command("ShellDock", wrap(function(r) r:dock {} end, true, true), {})

command("ShellHide", wrap(function(r) r:hide() end, true, true), {})

command(
  "ShellSend",
  wrap(function(r) r:send(vim.fn.input "To shell > ") end, true, true),
  {}
)

command("ShellSendLine", wrap(function(r) r:send_current_line() end, true, true), {})

command("ShellSendBuffer", wrap(function(r) r:send_buffer() end, true, true), {})

command(
  "ShellSendTillPoint",
  wrap(function(r) r:send_till_point() end, true, true),
  {}
)

command("ShellSendRange", wrap(function(r) r:send_visual_range() end, true, true), {})
