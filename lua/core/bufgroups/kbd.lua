require "core.bufgroups.commands"

K.bind(
  { noremap = true, leader = true },
  { "<tab>", ":GroupSelectAll<CR>", "Show all buffer groups" },
  { ".", ":GroupCurrentBufferSelect<CR>", "Show groups for current buf" }
)
