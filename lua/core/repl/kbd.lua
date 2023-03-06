Keybinding.bind(
  { leader = true, noremap = true, unique = true },
  { "xc", "<cmd>TerminateInputREPL sh<CR>", { name = "shell_terminate_input" } },
  { "xi", "<cmd>StartREPL sh<CR>", { name = "shell_start" } },
  { "xs", "<cmd>SplitREPL sh<CR>", { name = "shell_split" } },
  { "xv", "<cmd>VsplitREPL sh<CR>", { name = "shell_vsplit" } },
  { "xk", "<cmd>HideREPL sh<CR>", { name = "shell_hide" } },
  { "xq", "<cmd>StopREPL sh<CR>", { name = "shell_stop" } },
  { "xe", "<cmd>SendLineREPL sh<CR>", { name = "shell_send_line" } },
  { "xb", "<cmd>SendBufferREPL sh<CR>", { name = "shell_send_buffer" } },
  { "x.", "<cmd>SendTillPointREPL sh<CR>", { name = "shell_send_till_point" } },
  { "ri", "<cmd>StartREPL<CR>", { name = "repl_start" } },
  { "rs", "<cmd>SplitREPL<CR>", { name = "repl_split" } },
  { "rv", "<cmd>VsplitREPL<CR>", { name = "repl_vsplit" } },
  { "rk", "<cmd>HideREPL<CR>", { name = "repl_hide" } },
  { "rq", "<cmd>StopREPL<CR>", { name = "repl_stop" } },
  { "rQ", REPL.stopall, { desc = 'Stop all REPLs', name = "stop_all" } },
  { "re", "<cmd>SendLineREPL<CR>", { name = "repl_send_line" } },
  { "rb", "<cmd>SendBufferREPL<CR>", { name = "repl_send_buffer" } },
  { "r.", "<cmd>SendTillPointREPL<CR>", { name = "repl_send_till_point" } },
  { "re", "<cmd>SendRangeREPL<CR>", { name = "repl_send_range", mode = "v" } },
  { "xe", "<cmd>SendRangeREPL sh<CR>", { mode = "v", name = "shell_send_range" } },
  { "rc", "<cmd>TerminateInputREPL<CR>", { name = "repl_terminate_input", mode = "v" } }
)
