local g = Autocmd('Global')

g:create('TextYankPost', '*', V.partial(vim.highlight.on_yank, { timeout = 300 }))
