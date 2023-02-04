local g = Autocmd('Global')

g:create(
    'BufEnter',
    '*.tex',
    function()
        vim.wo.wrap = true
    end
)
