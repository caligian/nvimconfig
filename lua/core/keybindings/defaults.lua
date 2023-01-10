local opts = {noremap=true, silent=true}

vim.keymap.set('n', '<leader>fs', ':w %<CR>', opts)
vim.keymap.set('n', '<leader>fe', ':e!<CR>', opts)
vim.keymap.set('n', '<leader>bk', ':hide<CR>', opts)
vim.keymap.set('n', '<leader>bq', ':bwipeout %<CR>', opts)
vim.keymap.set('n', '<leader>tt', ':tabnew<CR>', opts)
vim.keymap.set('n', '<leader>tn', ':tabnext<CR>', opts)
vim.keymap.set('n', '<leader>tp', ':tabprev<CR>', opts)
vim.keymap.set('n', '<leader>te', ':tabedit NAME', opts)
vim.keymap.set('n', '<leader>w', '<C-w>', {})
vim.keymap.set('n', '<leader>ws', ':split <bar> wincmd k<CR>', {noremap=true})
vim.keymap.set('n', '<leader>wv', ':vsplit <bar> wincmd h<CR>', {noremap=true})
