require 'core.repl.commands'

Keybinding.bind(
  { leader = true, noremap = true },

  { "xe", "<esc>:ShellSendRange<CR>", { mode = "v", name = "shell_send_range" } },
  { "xc", "<cmd>ShellTerminateInput<CR>", { name = "shell_terminate_input" } },
  { "xd", "<cmd>ShellDock<CR>", { name = "shell_dock" } },
  { "xx", "<cmd>ShellStart<CR>", { name = "shell_start" } },
  { "xs", "<cmd>ShellSplit<CR>", { name = "shell_split" } },
  { "xv", "<cmd>ShellVsplit<CR>", { name = "shell_vsplit" } },
  { "xk", "<cmd>ShellHide<CR>", { name = "shell_hide" } },
  { "xq", "<cmd>ShellStop<CR>", { name = "shell_stop" } },
  { "xe", "<cmd>ShellSendLine<CR>", { name = "shell_send_line" } },
  { "xb", "<cmd>ShellSendBuffer<CR>", { name = "shell_send_buffer" } },
  { "x.", "<cmd>ShellSendTillPoint<CR>", { name = "shell_send_till_point" } },
  { "xf", "<cmd>ShellFloat<CR>", { name = "shell_float" } },
  { "xF", "<cmd>ShellFloatEditor<CR>", { name = "shell_float_editor" } },

  { "rd", "<cmd>REPLDock<CR>", { name = "repl_dock" } },
  { "rr", "<cmd>REPLStart<CR>", { name = "repl_start" } },
  { "rs", "<cmd>REPLSplit<CR>", { name = "repl_split" } },
  { "rv", "<cmd>REPLVsplit<CR>", { name = "repl_vsplit" } },
  { "rk", "<cmd>REPLHide<CR>", { name = "repl_hide" } },
  { "rq", "<cmd>REPLStop<CR>", { name = "repl_stop" } },
  { "rQ", "<cmd>REPLStopAll<CR>", { desc = "Stop all REPLs", name = "stop_all" } },
  { "re", "<cmd>REPLSendLine<CR>", { name = "repl_send_line" } },
  { "rb", "<cmd>REPLSendBuffer<CR>", { name = "repl_send_buffer" } },
  { "r.", "<cmd>REPLSendTillPoint<CR>", { name = "repl_send_till_point" } },
  { "rc", "<cmd>REPLTerminateInput<CR>", { name = "repl_terminate_input" } },
  { "re", "<esc>:REPLSendRange<CR>", { name = "repl_send_range", mode = "v" } },
  { "rf", "<cmd>REPLFloat<CR>", { name = "shell_float" } },
  { "rF", "<cmd>REPLFloatEditor<CR>", { name = "shell_float_editor" } }
)
