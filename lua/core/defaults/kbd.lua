-- Only works for toggleable options
local function _toggle_option(option)
  local bufnr = vim.fn.bufnr()
  local winid = vim.fn.bufwinid(bufnr)
  local ok, out = pcall(vim.api.nvim_buf_get_option, bufnr, option)

  if ok then vim.api.nvim_buf_set_option(bufnr, option, not out) end

  if not ok then
    ok, out = pcall(vim.api.nvim_win_get_option, winid, option)
    if ok then vim.api.nvim_win_set_option(winid, option, not out) end
  end
end

--------------------------------------------------------------------------------
--
K.bind {
  noremap = true,
  leader = true,

  --- Toggle zenmode
  {
    'oz',
    ':ToggleZenMode<CR>',
    'Toggle Zen mode',
  },

  -- File and buffer operations
  {
    "fb",
    "mA",
    { desc = "Bookmark current file at pos", name = "save_bookmark" },
  },
  {
    "fP",
    ":chdir ~/.config/nvim <bar> e .<CR>",
    { desc = "Open framework config", name = "framework_conf" },
  },
  {
    "fp",
    ":chdir ~/.nvim <bar> e .<CR>",
    { desc = "Open user config", name = "user_conf" },
  },
  { "be", ":e!<CR>", { desc = "Reload buffer", name = "reload_buffer" } },
  { "fs", ":w! %<CR>", { desc = "Save buffer", name = "save_buffer" } },
  { "bk", ":hide<CR>", { desc = "Hide buffer", name = "hide_buffer" } },
  {
    "bK",
    ":w! <bar> hide<CR>",
    { desc = "Save and hide buffer", name = "save_and_hide_buffer" },
  },
  { "bp", ":bprev<CR>", { desc = "Previous buffer", name = "prev_buffer" } },
  { "bn", ":bnext<CR>", { desc = "Next buffer", name = "next_buffer" } },
  { "b0", ":bfirst<CR>", { desc = "First buffer", name = "first_buffer" } },
  { "b$", ":blast<CR>", { desc = "Last buffer", name = "last_buffer" } },
  {
    "bl",
    ":b#<CR>",
    { desc = "Previously opened buffer", name = "recent_buffer" },
  },
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
  {
    "ee",
    "<cmd>NvimEvalLine<CR>",
    { desc = "Lua source line", name = "eval line" },
  },
  {
    "eb",
    "<cmd>NvimEvalBuffer<CR>",
    { desc = "Lua source buffer", name = "source_buffer" },
  },
  {
    "e.",
    "<cmd>NvimEvalTillPoint<CR>",
    { desc = "Lua source till point", name = "source_till_point" },
  },
  {
    "ee",
    "<esc><cmd>NvimEvalRegion<CR>",
    { desc = "Lua source range", mode = "v", name = "Lua source range" },
  },

  -- Scratch buffer stuff
  { ",", ":OpenScratch<CR>", { name = "open_scratch" } },
  { "F", ":OpenScratchFloat<CR>", { name = "open_scratch_float" } },
  {
    ";",
    ":OpenScratchVertically<CR>",
    { name = "open_scratch_vertically" },
  },

  -- Named tab switching (optional)
  {
    "tf",
    ":tabedit ",
    { desc = "Tab find file", name = "edit_buffer_in_tab" },
  },
  { "tt", ":tabnew<CR>", { desc = "New tab", name = "new_tab" } },
  { "tk", ":tabclose<CR>", { desc = "Close tab", name = "close_tab" } },
  { "tn", ":tabnext<CR>", { desc = "Next tab", name = "next_tab" } },
  { "tp", ":tabprev<CR>", { desc = "Previous tab", name = "prev_tab" } },

  -- Show startup logs
  {
    "hl",
    ":ShowLogs<CR>",
    { desc = "Show startup logs", name = "startup_logs" },
  },

  -- Quit
  { "qa", ":qa<CR>", ":qall" },
  { "qq", ":qa!<CR>", ":qall!" },
  { "qx", ":xa<CR>", ":xa" },

  -- Set options
  { "ot", partial(_toggle_option, "textwrap"), "Toggle wrapping" },
  { "or", partial(_toggle_option, "readonly"), "Toggle readonly" },
  { "oc", partial(_toggle_option, "cursorline"), "Toggle cursorline" },
  { "ol", partial(_toggle_option, "buflisted"), "Toggle buflisted" },
  { "ob", partial(_toggle_option, "backup"), "Toggle backup" },
  { "oe", partial(_toggle_option, "expandtab"), "Toggle expandtab" },
  { "os", partial(_toggle_option, "smartindent"), "Toggle smartindent" },
  { "o!", partial(_toggle_option, "modified"), "Toggle modified status" },
  { "ou", partial(_toggle_option, "ruler"), "Toggle ruler" },
  { "om", partial(_toggle_option, "modifiable"), "Toggle modifiable" },

  -- Window management
  { "wh", "<C-w>h", "Left win" },
  { "wo", "<C-w>o", "Hide other wins" },
  { "w_", "<C-w>_", "Max out height" },
  { "w|", "<C-w>|", "Max out width" },
  { "wj", "<C-w>j", "Down win" },
  { "wk", "<C-w>k", "Up win" },
  { "wl", "<C-w>l", "Right win" },
  { "w+", "<C-w>+", "Increase height" },
  { "w-", "<C-w>-", "Decrease height" },
  { "w=", "<C-w>=", "Equalize height and width" },
  { "w>", "<C-w>>", "Increase width" },
  { "w<", "<C-w><", "Decrease width" },
  { "ws", "<C-w>s", "Split win" },
  { "wv", "<C-w>v", "Vsplit win" },
  { "wt", "<C-w>T", "Tabnew win" },
  { "ww", "<C-w>w", "Other win" },
  { "wx", "<C-w>x", "Swap win" },

  -- Add comment separator line
  {
    "#",
    function()
      local tw = vim.bo.textwidth
      local comment = string.split(vim.bo.commentstring or "#", " ")[1]
      local l = #comment
      tw = tw == 0 and 50 or tw

      if l > 1 then
        comment = string.rep(comment, math.floor(tw / l))
      else
        comment = string.rep(comment, tw)
      end

      vim.api.nvim_put({ comment }, "l", true, true)
    end,
    "Add separator line",
  },
}

--------------------------------------------------------------------------------

K.noremap(
  "n",
  "\\\\",
  ":noh<CR>",
  { desc = "No highlight", silent = true, name = "noh" }
)

--------------------------------------------------------------------------------

K.noremap(
  "t",
  "<esc>",
  "<C-\\><C-n>",
  { desc = "Terminal to normal mode", name = "fix_esc_in_terminal" }
)

--------------------------------------------------------------------------------

local function dec_fontsize()
  user.currentfont:dec(1)
end

local function inc_fontsize()
  user.currentfont:inc(1)
end

K.bind {
  mode = 'in',
  { "<C-ScrollWheelUp>", inc_fontsize, "Increase font size by 1pt" },
  { "<C-ScrollWheelDown>", dec_fontsize, "Decrease font size by 1pt" },
}

K.bind {
  prefix = "<C-x>",
  noremap = true,
  silent = true,
  { "<C-=>", inc_fontsize, "Increase font size by 1pt" },
  { "<C-->", dec_fontsize, "Decrease font size by 1pt" },
}
