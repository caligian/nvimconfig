-- Trouble mappings
user.kbd.noremap_with_options({ silent = true },
    { "n", "<leader>ltt", "<cmd>TroubleToggle<cr>", { desc = 'Toggle trouble' } },
    { "n", "<leader>ltw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { desc = 'Workspace diagnostics' } },
    { "n", "<leader>ltd", "<cmd>TroubleToggle document_diagnostics<cr>", { desc = 'Document diagnostics' } },
    { "n", "<leader>ltl", "<cmd>TroubleToggle loclist<cr>", { desc = 'Show loclist' } },
    { "n", "<leader>ltq", "<cmd>TroubleToggle quickfix<cr>", { desc = 'Show qflist' } },
    { "n", "gR", "<cmd>TroubleToggle lsp_references<cr>", { desc = 'LSP references' } })

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
user.kbd.noremap_with_options({ silent = true },
    { 'n', '<leader>li', builtin.partial(vim.diagnostic.open_float, { scope = 'l', focus = false }),
        { desc = 'LSP diagnostic float' } },
    { 'n', '[d', vim.diagnostic.goto_prev, { desc = 'LSP go to previous diagnostic' } },
    { 'n', ']d', vim.diagnostic.goto_next, { desc = 'LSP go to next diagnostic' } },
    { 'n', '<leader>lq', vim.diagnostic.setloclist, { desc = 'LSP set loclist' } })
