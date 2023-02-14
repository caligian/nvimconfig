-- Disable this useless keybinding
vim.cmd("noremap gQ <nop>")

local defaults = Keybinding.defaults
local opts = { noremap = true, leader = true, mode = "n" }
defaults.save_bookmark =
  Keybinding.bind(opts, { "fb", "mA", { desc = "Bookmark current file at pos" } })
defaults.open_framework_config = Keybinding.bind(
  opts,
  { "fP", ":chdir ~/.config/nvim <bar> e .<CR>", { desc = "Open framework config" } }
)
defaults.open_user_config =
  Keybinding.bind(opts, { "fp", ":chdir ~/.nvim <bar> e .<CR>", { desc = "Open user config" } })
defaults.open_reload_buffer = Keybinding.bind(opts, { "be", ":e!<CR>", { desc = "Reload buffer" } })
defaults.save_buffer = Keybinding.bind(opts, { "fs", ":w %<CR>", { desc = "Save buffer" } })
defaults.hide_buffer = Keybinding.bind(opts, { "bk", ":hide<CR>", { desc = "Hide window" } })
defaults.previous_buffer =
  Keybinding.bind(opts, { "bp", ":bprev<CR>", { desc = "Previous buffer" } })
defaults.next_buffer = Keybinding.bind(opts, { "bn", ":bnext<CR>", { desc = "Next buffer" } })
defaults.first_buffer = Keybinding.bind(opts, { "b0", ":bfirst<CR>", { desc = "First buffer" } })
defaults.last_buffer = Keybinding.bind(opts, { "b$", ":blast<CR>", { desc = "Last buffer" } })
defaults.wipeout_buffer =
  Keybinding.bind(opts, { "bq", ":bwipeout % <bar> bprev<CR>", { desc = "Wipeout buffer" } })
defaults.source_vim_or_luafile = Keybinding.bind(opts, {
  "fv",
  ":w % <bar> :source %<CR>",
  {
    event = "BufEnter",
    pattern = { "*.vim", "*.lua" },
    desc = "Source vim or lua buffer",
  },
})
defaults.eval_line_easy =
  Keybinding.bind(opts, { "<leader>", "<cmd>NvimEvalLine<CR>", { desc = "Lua source line" } })
defaults.eval_line =
  Keybinding.bind(opts, { "ee", "<cmd>NvimEvalLine<CR>", { desc = "Lua source line" } })
defaults.eval_buffer =
  Keybinding.bind(opts, { "eb", "<cmd>NvimEvalBuffer<CR>", { desc = "Lua source buffer" } })
defaults.eval_till_point =
  Keybinding.bind(opts, { "e.", "<cmd>NvimEvalTillPoint<CR>", { desc = "Lua source till point" } })
defaults.eval_range = Keybinding.noremap(
  "v",
  "<leader><leader>",
  "<esc><cmd>NvimEvalRegion<CR>",
  { desc = "Lua source range" }
)
defaults.open_scratch =
  Keybinding.bind(opts, { ",", ":OpenScratch<CR>", { desc = "Open scratch buffer" } })
defaults.open_scratch_vertically = Keybinding.bind(
  opts,
  { ";", ":OpenScratchVertically<CR>", { desc = "Open scratch buffer vertically" } }
)
defaults.new_tab = Keybinding.bind(opts, { "tt", ":tabnew<CR>", { desc = "New tab" } })
defaults.next_tab = Keybinding.bind(opts, { "tn", ":tabnext<CR>", { desc = "Next tab" } })
defaults.prev_tab = Keybinding.bind(opts, { "tp", ":tabprev<CR>", { desc = "Previous tab" } })
defaults.open_file_in_tab =
  Keybinding.bind(opts, { "te", ":tabedit<CR>", { desc = "Open file in new tab" } })
defaults.close_tab = Keybinding.bind(opts, { "tk", ":tabclose<CR>", { desc = "Close tab" } })
defaults.first_tab = Keybinding.bind(opts, { "t1", ":tabnext 1<CR>", { desc = "Tab 1" } })
defaults.second_tab = Keybinding.bind(opts, { "t2", ":tabnext 2<CR>", { desc = "Tab 2" } })
defaults.third_tab = Keybinding.bind(opts, { "t3", ":tabnext 3<CR>", { desc = "Tab 3" } })
defaults.fourth_tab = Keybinding.bind(opts, { "t4", ":tabnext 4<CR>", { desc = "Tab 4" } })
defaults.fifth_tab = Keybinding.bind(opts, { "t5", ":tabnext 5<CR>", { desc = "Tab 5" } })
defaults.sixth_tab = Keybinding.bind(opts, { "t6", ":tabnext 6<CR>", { desc = "Tab 6" } })
defaults.seventh_tab = Keybinding.bind(opts, { "t7", ":tabnext 7<CR>", { desc = "Tab 7" } })
defaults.eighth_tab = Keybinding.bind(opts, { "t8", ":tabnext 8<CR>", { desc = "Tab 8" } })
defaults.ninth_tab = Keybinding.bind(opts, { "t9", ":tabnext 9<CR>", { desc = "Tab 9" } })
defaults.tenth_tab = Keybinding.bind(opts, { "t0", ":tabnext 10<CR>", { desc = "Tab 10" } })
defaults.show_startup_logs =
  Keybinding.bind(opts, { "hl", ":ShowLogs<CR>", { desc = "Show startup logs" } })
defaults.no_highlight =
  Keybinding.noremap("n", "\\\\", ":noh<CR>", { desc = "No highlight", silent = true })
defaults.window_management =
  Keybinding.noremap("n", "<leader>w", "<C-w>", { silent = true, desc = "Window commands" })
defaults.fix_escape_in_terminal =
  Keybinding.noremap("t", "<esc>", "<C-\\><C-n>", { desc = "Terminal to normal mode" })
defaults.hide_help_buffer_quickly =
  Keybinding.noremap("n", "gQ", ":hide<CR>", { event = "FileType", pattern = "help" })
