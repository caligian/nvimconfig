local fugitive = plugin.get('fugitive')

fugitive.mappings = {
    opts = {leader = true, prefix='<leader>g'},
    status = {'g', ':vert Git<CR>', {desc = 'show status'}},
    stage = {'s', ':Git stage %<CR>', {desc = 'stage buffer'}},
    unstage = {'s', ':Git unstage %<CR>', {desc = 'unstage buffer'}},
    add = {'s', ':Git add %<CR>', {desc = 'add buffer'}},
    commit = {'s', ':Git commit<CR>', {desc = 'commit buffer'}},
}
