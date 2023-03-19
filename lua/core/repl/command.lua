local command = utils.command

local function get_repl(is_shell)
  local ft
  if is_shell then
    ft = 'sh'
  else
    ft = vim.bo.filetype
    if #ft == 0 then
      return
    end
  end

  if not table.contains(Lang.langs, ft, "repl") then return end
  local current = vim.fn.bufnr()
  local exists = table.contains(REPL.ids, ft, current)
  if exists then return exists end

  local r = REPL(is_shell)
  return  r
end

local function wrap(f, ft)
  return function()
    local r = get_repl(ft)
    if r then f(r) end
  end
end

command(
  "REPLStart",
  wrap(function(r) r:split("s", { resize = 0.3, min = 0.1 }) end),
  {}
)

command("REPLTerminateInput", wrap(function(r) r:terminate_input() end), {})

command("REPLStop", wrap(function(r) r:stop() end), {})

command(
  "REPLSplit",
  wrap(function(r) r:split("s", { resize = 0.3, min = 0.1 }) end),
  {}
)

command(
  "REPLVsplit",
  wrap(function(r) r:split("v", { resize = 0.3, min = 0.1 }) end),
  {}
)

command("REPLDock", wrap(function(r) r:dock() end), {})

command("REPLHide", wrap(function(r) r:hide() end), {})

command(
  "REPLSend",
  wrap(function(r) r:send(vim.fn.input "To REPL > ") end),
  {}
)

command("REPLSendLine", wrap(function(r) r:send_current_line() end), {})

command("REPLSendBuffer", wrap(function(r) r:send_buffer() end), {})

command("REPLSendTillPoint", wrap(function(r) r:send_till_point() end), {})

command("REPLSendRange", wrap(function(r) r:send_visual_range() end), {})

-- Shell
command(
  "ShellStart",
  wrap(function(r) r:split("s", { resize = 0.3, min = 10, full = true }) end, true),
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
  wrap(function(r) r:split("Shells", { resize = 0.3, min = 0.1, full = true }) end, true),
  {}
)

command(
  "ShellVsplit",
  wrap(function(r) r:split("Shellv", { resize = 0.3, min = 0.1, full = true }) end, true),
  {}
)

command("ShellDock", wrap(function(r) r:dock { full = true } end, true), {})

command("ShellHide", wrap(function(r) r:hide() end, true), {})

command(
  "ShellSend",
  wrap(function(r) r:send(vim.fn.input "To shell > ") end, true),
  {}
)

command(
  "ShellSendLine",
  wrap(function(r) r:send_current_line() end, true),
  {}
)

command(
  "ShellSendBuffer",
  wrap(function(r) r:send_buffer() end, true),
  {}
)

command(
  "ShellSendTillPoint",
  wrap(function(r) r:send_till_point() end, true),
  {}
)

command(
  "ShellSendRange",
  wrap(function(r) r:send_visual_range() end, true),
  {}
)
