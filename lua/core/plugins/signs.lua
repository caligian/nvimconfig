local gs = require "gitsigns"
local signs = {}

signs.methods = {
  next_hunk = function()
    if vim.wo.diff then
      return "]c"
    end
    vim.schedule(function()
      gs.next_hunk()
    end)
    return "<Ignore>"
  end,

  previous_hunk = function()
    if vim.wo.diff then
      return "[c"
    end
    vim.schedule(function()
      gs.prev_hunk()
    end)
    return "<Ignore>"
  end,
}

-- mappings vs kbd? mappings will be used internally. kbd will be set externally
-- If kbd is missing then K.bind won't be autocalled while mappings will be
-- continued to be used by plugins
signs.mappings = {
  next_hunk = {
    "n",
    "]c",
    signs.methods.next_hunk,
    { expr = true, desc = "Next hunk" },
  },
  previous_hunk = {
    "n",
    "[c",
    signs.methods.previous_hunk,
    { expr = true, desc = "Previous hunk" },
  },
  stage_hunk = {
    "n",
    "<leader>ghs",
    ":Gitsigns stage_hunk<CR>",
    { mode = "nv", desc = "Stage hunk" },
  },
  reset_hunk = {
    "n",
    "<leader>ghr",
    ":Gitsigns reset_hunk<CR>",
    "Reset hunk",
  },
  stage_buffer = {
    "n",
    "<leader>gs",
    gs.stage_buffer,
    "Stage buffer",
  },
  reset_buffer = {
    "n",
    "<leader>g!",
    gs.reset_buffer,
    "Reset buffer",
  },
  undo_staged_hunk = {
    "n",
    "<leader>ghu",
    gs.undo_stage_hunk,
    "Undo staged hunk",
  },
  blame_line = {
    "n",
    "<leader>ghb",
    function()
      gs.blame_line { full = true }
    end,
    "Blame line",
  },
  toggle_current_line_blame = {
    "n",
    "<leader>gtb",
    gs.toggle_current_line_blame,
    "Blame current line",
  },
  diffthis = {
    "n",
    "<leader>ghd",
    gs.diffthis,
    "Diff this",
  },
  diffthis1 = {
    "n",
    "<leader>ghD",
    function()
      gs.diffthis "~"
    end,
    "Diff this (~)",
  },
  toggled_deleted = {
    "n",
    "<leader>gtd",
    gs.toggle_deleted,
    {},
  },
}

function signs:setup()
  gs.setup(self.config)
end

return signs
