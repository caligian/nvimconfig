user.plugins['trouble.nvim'] = {
    icons = true,
    fold_open = "v",
    fold_closed = ">",
    indent_lines = false,
    use_diagnostic_signs = false,
    signs = {
        error = "Error",
        warning = "Warn",
        hint = "Hint",
        information = "Info",
        other = "Misc"
    },
}
V.require 'user.plugins.trouble_nvim'
V.require('trouble').setup(user.plugins['trouble.nvim'])

Keybinding({ silent = true, noremap = true, leader = true }):bind {
    { "ltt", "<cmd>TroubleToggle<cr>", { desc = 'Toggle trouble' } },
    { "ltw", "<cmd>TroubleToggle workspace_diagnostics<cr>", { desc = 'Workspace diagnostics' } },
    { "ld", "<cmd>TroubleToggle document_diagnostics<cr>", { desc = 'Document diagnostics' } },
    { "ltl", "<cmd>TroubleToggle loclist<cr>", { desc = 'Show loclist' } },
    { "ltq", "<cmd>TroubleToggle quickfix<cr>", { desc = 'Show qflist' } },
}
