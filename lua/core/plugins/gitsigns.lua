local gs = require "gitsigns"
local plug = plugin.gitsigns

plug.methods = {
  next_hunk = function()
    if vim.wo.diff then return "]c" end
    vim.schedule(function() gs.next_hunk() end)
    return "<Ignore>"
  end,

  previous_hunk = function()
    if vim.wo.diff then return "[c" end
    vim.schedule(function() gs.prev_hunk() end)
    return "<Ignore>"
  end,
}

-- mappings vs kbd? mappings will be used internally. kbd will be set externally
-- If kbd is missing then K.bind won't be autocalled while mappings will be
-- continued to be used by plugins
plug.mappings = {
  {
    'n',
    "]c",
    plug.methods.next_hunk,
    { expr = true, desc = "Next hunk" },
  },
  {
    'n',
    "[c",
    plug.methods.previous_hunk,
    { expr = true, desc = "Previous hunk" },
  },
  {
    prefix = '<leader>g',
    {
      "hs",
      ":Gitsigns stage_hunk<CR>",
      { mode = "nv", desc = "Stage hunk" },
    },
    {
      "hr",
      ":Gitsigns reset_hunk<CR>",
      "Reset hunk",
    },
    {
      "s",
      gs.stage_buffer,
      "Stage buffer",
    },
    {
      "!",
      gs.reset_buffer,
      "Reset buffer",
    },
    {
      "hu",
      gs.undo_stage_hunk,
      "Undo staged hunk",
    },
    {
      "hp",
      gs.preview_hunk,
      "Preview hubk",
    },
    {
      "hb",
      function() gs.blame_line { full = true } end,
      "Blame line",
    },
    {
      "tb",
      gs.toggle_current_line_blame,
      "Blame current line",
    },
    {
      "hd",
      gs.diffthis,
      "Diff this",
    },
    {
      "hD",
      function() gs.diffthis "~" end,
      "Diff this (~)",
    },
    { "td", gs.toggle_deleted, {} },
  },
  {
    "ox",
    "ih",
    ":<C-U>Gitsigns select_hunk<CR>",
    { desc = "Select hunk" },
  },
}

plug.config = {
  on_attach = function(bufnr)
    local self = plugin.gitsigns
    local kbd = vim.deepcopy(self.mappings)
    if K._ismultiple(kbd) then
      kbd.buffer = bufnr
    else
      for i = 1, #kbd do
        if K._ismultiple(kbd[i]) then
          kbd[i].buffer = bufnr
          K._applymultiple(kbd[i])
        else
          local k = vim.deepcopy(kbd[i])
          local opts = k[4] or {}
          opts = is_string(opts) and {desc=opts} or opts
          opts = dict.copy(opts)
          opts.buffer = bufnr
          k[4] = opts
          K.map(unpack(k))
        end
      end
    end
  end,
}

function plug:on_attach() require("gitsigns").setup(self.config) end
