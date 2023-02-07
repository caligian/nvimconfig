Keybinding({
    noremap = true,
    leader = true,
    silent = true,
}):bind {
    -- Buffer and file
    { 'fs', ':w %<CR>', 'Save buffer' },
    { 'fP', ':chdir ~/.config/nvim <bar> e .<CR>', 'Open default config' },
    { 'fp', ':chdir ~/.nvim <bar> e .<CR>', 'Open private config' },
    {
        'fv', ':w % <bar> :source %<CR>',
        {
            event = 'BufEnter',
            pattern = { '*.vim', '*.lua' },
            desc = 'Source vim/lua buffer'
        }
    },
    { 'be', ':e!<CR>', 'Reload buffer' },
    { 'bk', ':hide<CR>', 'Hide window' },
    { 'bp', ':bprev<CR>', 'Previous buffer' },
    { 'bn', ':bnext<CR>', 'Next buffer' },
    { 'b0', ':bfirst<CR>', 'First buffer' },
    { 'b$', ':blast<CR>', 'Last buffer' },
    { 'bq', ':bwipeout %<CR>', 'Wipeout buffer' },
    { 'b0', ':bfirst<CR>', 'First buffer' },

    -- Neovim lua eval
    { '<leader>', '<cmd>NvimEvalLine<CR>', 'Lua source line' },
    { 'ee', '<cmd>NvimEvalLine<CR>', 'Lua source line' },
    { 'eb', '<cmd>NvimEvalBuffer<CR>', 'Lua source buffer' },
    { 'e.', '<cmd>NvimEvalTillPoint<CR>', 'Lua source till point' },
    {
        '<leader>', '<esc><cmd>NvimEvalRegion<CR>', {
            desc = 'Lua source range',
            mode = 'v'
        }
    },

    -- Scratch buffer
    { ',', ':OpenScratch<CR>', 'Open scratch buffer' },
    { ';', ':OpenScratchVertically<CR>', 'Open scratch buffer vertically' },

    -- Tab operations
    { 'tt', ':tabnew<CR>', 'New tab' },
    { 'tn', ':tabnext<CR>', 'Next tab' },
    { 'tp', ':tabprev<CR>', 'Previous tab' },
    { 'te', ':tabedit<CR>', 'Open file in new tab' },
    { 'tk', ':tabclose<CR>', 'Close tab' },
    { 't1', ':tabnext 1<CR>', 'Tab 1' },
    { 't2', ':tabnext 2<CR>', 'Tab 2' },
    { 't3', ':tabnext 3<CR>', 'Tab 3' },
    { 't4', ':tabnext 4<CR>', 'Tab 4' },
    { 't5', ':tabnext 5<CR>', 'Tab 5' },
    { 't6', ':tabnext 6<CR>', 'Tab 6' },
    { 't7', ':tabnext 7<CR>', 'Tab 7' },
    { 't8', ':tabnext 8<CR>', 'Tab 8' },
    { 't9', ':tabnext 9<CR>', 'Tab 9' },
    { 't0', ':tabnext 10<CR>', 'Tab 10' },

    -- Show logs
    { 'hl', ':ShowLogs<CR>', 'Show startup logs' },
}

-- Fix <esc> in Terminal
Keybinding.noremap('n', '\\\\', ':noh<CR>', { desc = 'No highlight', silent = true })

-- Window management
Keybinding.map('n', '<leader>w', '<C-w>', { silent = true, desc = 'Window commands' })
