Keybinding.bind(
  { noremap = true, leader = true, mode = "n" },
  { "gs", ":Git stage %<CR>", { desc = "Stage buffer", name = "stage_buffer" } },
  { "gc", ":Git commit <CR>", { desc = "Commit buffer", name = "commit buffer" } },
  { "gg", ":tab Git<CR>", { desc = "Open Fugitive", name = "fugitive" } }
)

req "user.plugins.vim-fugitive"
