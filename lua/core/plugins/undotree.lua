local undotree = {}

undotree.mappings = {
  undotree = {
    "n",
    "<leader>u",
    vim.cmd.UndotreeToggle,
    "Show undotree",
  },
}

return undotree
