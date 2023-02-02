user.kbd({
    noremap = true,
    silent = true,
    leader = true,
}):bind {
    { 'fs', ':w %<CR>', { desc = 'Save buffer' } },
    { 'be', ':e!<CR>', { desc = 'Reload buffer' } },
    { 'bk', ':hide<CR>', { desc = 'Hide window' } },
    { 'bp', ':bprev<CR>', { desc = 'Previous buffer' } },
    { 'bn', ':bnext<CR>', { desc = 'Next buffer' } },
    { 'b0', ':bfirst<CR>', { desc = 'First buffer' } },
    { 'b$', ':blast<CR>', { desc = 'Last buffer' } },
    { 'bq', ':bwipeout %<CR>', { desc = 'Wipeout buffer' } },
}
