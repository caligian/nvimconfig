require "core.bookmarks.commands"

K.bind(
  { prefix = "gb" },
  { "a", ":BookmarkLine<CR>", "Add current line" },
  { "x", ":BookmarkRemoveLine<CR>", "Remove line" },
  { "?", ":BookmarkCurrentBufferPicker<CR>", "Telescope current buffer lines" },
  { "X", ":BookmarkRemoveCurrentBufferPicker<CR>", "Telescope & remove lines" }
)

K.map(
  "n",
  "<leader>>",
  ":BookmarkCurrentBufferPicker<CR>",
  "Telescope current buffer lines"
)
K.map("n", "gB", ":BookmarkToggleLine<CR>", "Toggle current line")
K.map("n", "<leader>`", ":BookmarkPicker<CR>", "Telescope bookmarks")
K.map(
  "n",
  "<leader>~",
  ":BookmarkRemovePicker<CR>",
  "Telescope & remove bookmarks"
)
