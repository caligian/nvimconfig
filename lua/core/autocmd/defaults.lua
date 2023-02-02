local anon = user.autocmd()

anon:create('BufEnter', '*.tex', function() vim.wo.wrap = true end, { name = 'EnableWindowWrapInLatex' })
