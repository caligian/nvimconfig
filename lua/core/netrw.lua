vim.g.netrw_banner = 0

K.bind(
  { noremap = true },
  { "<leader>|", ":Lexplore <bar> vert resize 40<CR>", "Open netrw" },
  {
    "g?",
    ":h netrw-quickmap<CR>",
    { event = "FileType", pattern = "netrw", desc = "Help" },
  }
)
