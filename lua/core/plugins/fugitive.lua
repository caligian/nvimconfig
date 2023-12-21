local fugitive = {}

fugitive.mappings = {
  status = {
    "n",
    "<leader>gg",
    ":vert Git<CR>",
    { desc = "show status" },
  },
  stage = {
    "n",
    "<leader>gs",
    ":Git stage %<CR>",
    { desc = "stage buffer" },
  },
  add = {
    "n",
    "<leader>ga",
    ":Git add %<CR>",
    { desc = "add buffer" },
  },
  commit = {
    "n",
    "<leader>gc",
    ":Git commit<CR>",
    { desc = "commit buffer" },
  },
  push = {
    "n",
    "<leader>gp",
    ":! git push<CR>",
    { desc = "push buffer" },
  },
}

return fugitive

