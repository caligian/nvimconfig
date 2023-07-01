local undotree = plugin.get 'undotree'

undotree.mappings = {
  undotree = {
    undotree = {'n', '<leader>u', vim.cmd.UndotreeToggle, 'Show undotree'}
  }
}
