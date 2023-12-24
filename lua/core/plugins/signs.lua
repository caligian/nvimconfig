signs = {
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
    signs.next_hunk,
    { expr = true, desc = "Next hunk" },
  },
  previous_hunk = {
    "n",
    "[c",
    signs.previous_hunk,
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
    ':Gitsigns stage_buffer<CR>',
    "Stage buffer",
  },
  reset_buffer = {
    "n",
    "<leader>g!",
    ':Gitsigns reset_buffer<CR>',
    "Reset buffer",
  },
  undo_staged_hunk = {
    "n",
    "<leader>ghu",
    ':Gitsigns undo_stage_hunk<CR>',
    "Undo staged hunk",
  },
  blame_line = {
    "n",
    "<leader>ghb",
    function()
      local gs = require('gitsigns')
      gs.blame_line { full = true }
    end,
    "Blame line",
  },
  toggle_current_line_blame = {
    "n",
    "<leader>gtb",
    ':Gitsigns toggle_current_line_blame<CR>',
    "Blame current line",
  },
  diffthis = {
    "n",
    "<leader>ghd",
    ':Gitsigns diffthis<CR>',
    "Diff this",
  },
  diffthis1 = {
    "n",
    "<leader>ghD",
    function()
      local gs = require('gitsigns')
      gs.diffthis "~"
    end,
    "Diff this (~)",
  },
  toggled_deleted = {
    "n",
    "<leader>gtd",
    ':Gitsigns toggle_deleted<CR>',
    {},
  },
}

function signs:setup()
  local gs = require('gitsigns')
  gs.setup(self.config)
end

return signs
