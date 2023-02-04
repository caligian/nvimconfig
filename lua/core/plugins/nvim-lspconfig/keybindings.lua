-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
Keybinding({ silent = true }):bind {
    {
        '<leader>li',
        V.partial(vim.diagnostic.open_float, { scope = 'l', focus = false }),
        { desc = 'LSP diagnostic float' }
    },
    { '[d', vim.diagnostic.goto_prev, { desc = 'LSP go to previous diagnostic' } },
    { ']d', vim.diagnostic.goto_next, { desc = 'LSP go to next diagnostic' } },
    { '<leader>lq', vim.diagnostic.setloclist, { desc = 'LSP set loclist' } }
}
