local g = Autocmd('Global')

g:create('BufEnter', '*.tex', function() vim.wo.wrap = true end)
g:create('TextYankPost', '*', V.partial(vim.highlight.on_yank, { timeout = 300 }))
