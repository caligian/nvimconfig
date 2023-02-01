vim.g.mapleader = ' '
vim.g.localleader = ','

Keybinding.map('n', '<leader>w', '<C-w>', { silent = true, desc = 'Window commands' })
Keybinding.noremap('n', '\\\\', ':noh<CR>', {desc='No highlight'})
Keybinding.noremap('t', '<esc>', '<C-\\><C-n>', {desc='Terminal to normal mode'})

Keybinding({
    noremap = true,
    silent = true,
    leader = true,
}):bind {
    { 'fs', ':w %<CR>', { desc = 'Save buffer' } },
    { 'fe', ':e!<CR>', { desc = 'Reload buffer' } },
    { 'bk', ':hide<CR>', { desc = 'Hide window' } },
    { 'bp', ':bprev<CR>', { desc = 'Previous buffer' } },
    { 'bn', ':bnext<CR>', { desc = 'Next buffer' } },
    { 'b0', ':bfirst<CR>', { desc = 'First buffer' } },
    { 'b$', ':blast<CR>', { desc = 'Last buffer' } },
    { 'bq', ':bwipeout %<CR>', { desc = 'Wipeout buffer' } },
    { 'tt', ':tabnew<CR>', { desc = 'New tab' } },
    { 'tn', ':tabnext<CR>', { desc = 'Next tab' } },
    { 'tp', ':tabprev<CR>', { desc = 'Previous tab' } },
    { 'te', ':tabedit<CR>', { desc = 'Open file in new tab' } },
    { 'tk', ':tabclose<CR>', { desc = 'Close tab' } },
    { 't1', ':tabnext 1<CR>', { desc = 'Tab 1' } },
    { 't2', ':tabnext 2<CR>', { desc = 'Tab 2' } },
    { 't3', ':tabnext 3<CR>', { desc = 'Tab 3' } },
    { 't4', ':tabnext 4<CR>', { desc = 'Tab 4' } },
    { 't5', ':tabnext 5<CR>', { desc = 'Tab 5' } },
    { 't6', ':tabnext 6<CR>', { desc = 'Tab 6' } },
    { 't7', ':tabnext 7<CR>', { desc = 'Tab 7' } },
    { 't8', ':tabnext 8<CR>', { desc = 'Tab 8' } },
    { 't9', ':tabnext 9<CR>', { desc = 'Tab 9' } },
    { 't0', ':tabnext 10<CR>', { desc = 'Tab 10' } },
} 

Keybinding({
    event = 'BufNew', 
    pattern = {'*.lua', '*.vim'},
    noremap = true, 
    leader = true
}):bind {
    {'fv', ':w <bar> :source % <CR>'}
}
