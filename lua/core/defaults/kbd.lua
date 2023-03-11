-- Disable this useless keybinding
vim.cmd "noremap gQ <nop>"

local function clean_before_quitting()
  for _, buf in pairs(Buffer.ids) do
    buf:delete()
  end

  REPL.stopall()
end

K.bind(
  { noremap = true, leader = true },

  -- File and buffer operations
  { "fb", "mA", { desc = "Bookmark current file at pos", name = "save_bookmark" } },
  {
    "fP",
    ":chdir ~/.config/nvim <bar> e .<CR>",
    { desc = "Open framework config", name = "framework_conf" },
  },
  { "fp", ":chdir ~/.nvim <bar> e .<CR>", { desc = "Open user config", name = "user_conf" } },
  { "be", ":e!<CR>", { desc = "Reload buffer", name = "reload_buffer" } },
  { "fs", ":w! %<CR>", { desc = "Save buffer", name = "save_buffer" } },
  { "bk", ":hide<CR>", { desc = "Hide buffer", name = "hide_buffer" } },
  { "bK", ":w! <bar> hide<CR>", { desc = "Save and hide buffer", name = "save_and_hide_buffer" } },
  { "bP", ":bprev<CR>", { desc = "Previous buffer", name = "prev_buffer" } },
  { "bN", ":bnext<CR>", { desc = "Next buffer", name = "next_buffer" } },
  { "b0", ":bfirst<CR>", { desc = "First buffer", name = "first_buffer" } },
  { "b$", ":blast<CR>", { desc = "Last buffer", name = "last_buffer" } },
  { "bl", ":b#<CR>", { desc = "Previously opened buffer", name = "recent_buffer" } },
  {
    "fv",
    ":w! % <bar> :source %<CR>",
    {
      event = "BufEnter",
      pattern = { "*.vim", "*.lua" },
      desc = "Source vim or lua buffer",
      name = "source",
    },
  },

  -- Lua eval anywhere like emacs eval-sexp, etc
  { "<leader>", "<cmd>NvimEvalLine<CR>", { desc = "Lua source line", name = "eval_line" } },
  { "ee", "<cmd>NvimEvalLine<CR>", { desc = "Lua source line", name = "eval line" } },
  { "eb", "<cmd>NvimEvalBuffer<CR>", { desc = "Lua source buffer", name = "source_buffer" } },
  {
    "e.",
    "<cmd>NvimEvalTillPoint<CR>",
    { desc = "Lua source till point", name = "source_till_point" },
  },
  {
    "<leader>",
    "<esc><cmd>NvimEvalRegion<CR>",
    { desc = "Lua source range", mode = "v", name = "Lua source range" },
  },

  -- Scratch buffer stuff
  { ",", ":OpenScratch<CR>", { desc = "Open scratch buffer", name = "open_scratch" } },
  {
    ";",
    ":OpenScratchVertically<CR>",
    { desc = "Open scratch buffer vertically", name = "open_scratch_vertically" },
  },

  -- Named tab switching (optional)
  { "tf", ":tabedit ", { desc = "Tab find file", name = "edit_buffer_in_tab" } },
  { "tt", ":tabnew<CR>", { desc = "New tab", name = "new_tab" } },
  { "tk", ":tabclose<CR>", { desc = "Close tab", name = "close_tab" } },
  { "tn", ":tabnext<CR>", { desc = "Next tab", name = "next_tab" } },
  { "tp", ":tabprev<CR>", { desc = "Previous tab", name = "prev_tab" } },

  -- Show startup logs
  { "hl", ":ShowLogs<CR>", { desc = "Show startup logs", name = "startup_logs" } },

  -- Quit
  {
    "qa",
    function()
      clean_before_quitting()
      vim.cmd "qa"
    end,
    { desc = ":qall" },
  },
  {
    "qq",
    function()
      clean_before_quitting()
      vim.cmd "qa!"
    end,
  },
  {
    "qx",
    function()
      clean_before_quitting()
      vim.cmd "xa"
    end,
  },

  -- Set options
  { "hot", ":setlocal textwrap<CR>", "Set text wrapping" },
  { "hor", ":setlocal readonly<CR>", "Set readonly" },

  -- Window management
  { "w", "<C-w>", "Window commands" }
)

K.noremap("n", "\\\\", ":noh<CR>", { desc = "No highlight", silent = true, name = "noh" })

K.noremap(
  "t",
  "<esc>",
  "<C-\\><C-n>",
  { desc = "Terminal to normal mode", name = "fix_esc_in_terminal" }
)

K.bind(
  { prefix = "<C-x>", noremap = true, silent = true },
  { "<C-->", ":FontSize -1<CR>", "Decrease font size by 1pt" },
  { "<C-=>", ":FontSize +1<CR>", "Increase font size by 1pt" }
)
