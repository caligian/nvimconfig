Autocmd(false, 'TextYankPost', '*', V.partial(vim.highlight.on_yank, { timeout = 100 }))
