local REPL = require 'core.repl.REPL'
local command = utils.command

local function wrap(f, is_shell)
  return function(args)
    local ft = args.args

    if is_shell then
      ft = "sh"
    elseif #ft == 0 then
      ft = vim.bo.filetype
    end

    local r = REPL.create(ft, vim.fn.bufnr())
    if r then f(r) end
  end
end

local function shell_wrap(f)
  return wrap(f, true)
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
  wrap(function(r) r:split("s", { resize = 0.4, min = 0.1 }) end),
  { nargs = "?", complete = get_builtin }
)

command(
  "REPLTerminateInput",
  wrap(function(r) r:terminate_input() end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLStop",
  wrap(function(r) r:stop() end),
  { complete = get_builtin, nargs = "?" }
)

command(
  'REPLStopAll',
  REPL.stopall,
  {}
)

command(
  "REPLFloatEditor",
  wrap(function(r) r:center_float { relative = "editor" } end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLFloat",
  wrap(function(r) r:center_float { relative = "win" } end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSplit",
  wrap(function(r) r:split("s", { resize = 0.4, min = 0.1 }, false) end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLVsplit",
  wrap(function(r) r:split("v", { resize = 0.5, min = 0.1 }, false) end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLDock",
  wrap(function(r) r:dock { relative = "win" } end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLHide",
  wrap(function(r) r:hide() end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendNode",
  wrap(function(r) r:send_node_at_cursor() end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSend",
  wrap(function(r) r:send(vim.fn.input "To REPL > ") end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendLine",
  wrap(function(r) r:send_current_line() end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendBuffer",
  wrap(function(r) r:send_buffer() end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendTillPoint",
  wrap(function(r) r:send_till_point() end),
  { complete = get_builtin, nargs = "?" }
)

command(
  "REPLSendRange",
  wrap(function(r) r:send_visual_range() end),
  { complete = get_builtin, nargs = "?" }
)

-- Shell
command(
  "ShellStart",
  shell_wrap(function(r) r:split("s", { resize = 0.4, min = 10, full = true }) end),
  {}
)

command(
  "ShellTerminateInput",
  shell_wrap(function(r) r:terminate_input() end),
  {}
)

command(
  "ShellStop",
  shell_wrap(function(r) r:stop() end),
  {}
)

command(
  "ShellSplit",
  shell_wrap(function(r) r:split("s", { resize = 0.4, min = 0.1, full = true }) end),
  {}
)

command(
  "ShellVsplit",
  shell_wrap(function(r) r:split("v", { resize = 0.5, min = 0.1, full = true }) end),
  {}
)

command(
  "ShellDock",
  shell_wrap(function(r) r:dock {} end),
  {}
)

command(
  "ShellHide",
  shell_wrap(function(r) r:hide() end),
  {}
)

command(
  "ShellSend",
  shell_wrap(function(r) r:send(vim.fn.input "To shell > ") end),
  {}
)

command(
  "ShellSendLine",
  shell_wrap(function(r) r:send_current_line() end),
  {}
)

command(
  "ShellSendBuffer",
  shell_wrap(function(r) r:send_buffer() end),
  {}
)

command(
  "ShellSendTillPoint",
  shell_wrap(function(r) r:send_till_point() end),
  {}
)

command(
  "ShellFloatEditor",
  shell_wrap(function(r) r:center_float { relative = "editor" } end),
  {}
)

command(
  "ShellFloat",
  shell_wrap(function(r) r:center_float { relative = "win" } end),
  {}
)

command(
  "ShellSendRange",
  shell_wrap(function(r) r:send_visual_range() end),
  {}
)

command(
  "ShellSendNode",
  shell_wrap(function(r) r:send_node_at_cursor() end),
  { complete = get_builtin, nargs = "?" }
)
