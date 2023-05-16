local gs = require "gitsigns"
local plug = plugin.gitsigns

plug.methods = {
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
plug.mappings = {
  noremap = true,
  {
    "]c",
    plug.methods.next_hunk,
    { expr = true, desc = "Next hunk" },
  },
  {
    "[c",
    plug.methods.previous_hunk,
    { expr = true, desc = "Previous hunk" },
  },
  {
    "<leader>ghs",
    ":Gitsigns stage_hunk<CR>",
    { mode = "nv", desc = "Stage hunk" },
  },
  {
    "<leader>ghr",
    ":Gitsigns reset_hunk<CR>",
    "Reset hunk",
  },
  {
    "<leader>gs",
    gs.stage_buffer,
    "Stage buffer",
  },
  {
    "<leader>g!",
    gs.reset_buffer,
    "Reset buffer",
  },
  {
    "<leader>ghu",
    gs.undo_stage_hunk,
    "Undo staged hunk",
  },
  {
    "<leader>ghp",
    gs.preview_hunk,
    "Preview hubk",
  },
  {
    "<leader>ghb",
    function()
      gs.blame_line { full = true }
    end,
    "Blame line",
  },
  {
    "<leader>gtb",
    gs.toggle_current_line_blame,
    "Blame current line",
  },
  {
    "<leader>ghd",
    gs.diffthis,
    "Diff this",
  },
  {
    "<leader>ghD",
    function()
      gs.diffthis "~"
    end,
    "Diff this (~)",
  },
  { "<leader>gtd", gs.toggle_deleted },
  {
    "ih",
    ":<C-U>Gitsigns select_hunk<CR>",
    { mode = "ox", desc = "Select hunk" },
  },
}

plug.config = {
  on_attach = function(bufnr)
    local self = plugin.gitsigns
    local kbd = utils.copy(self.mappings)
    kbd.buffer = bufnr
    K.bind(kbd)
  end,
}

function plug:on_attach()
  require("gitsigns").setup(self.config)
end
