vim.api.nvim_create_autocmd({'BufEnter'}, {
    pattern = '*tex',
    callback = function()
        vim.wo.wrap = true
    end
})
