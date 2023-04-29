utils = utils or {}
utils.command = vim.api.nvim_create_user_command
utils.autocmd = vim.api.nvim_create_autocmd
utils.augroup = vim.api.nvim_create_augroup
utils.bindkeys = vim.keymap.set
utils.remkeys = vim.keymap.del
