return {
    { 'wbthomason/packer.nvim' },
    { 'Olical/conjure' },
    { 'justinmk/vim-sneak' },
    { 'tpope/vim-commentary', keys = { { 'v', 'g' } } },
    { 'jasonccox/vim-wayland-clipboard' },
    {
        'tpope/vim-fugitive',
        keys = { { 'n', '<leader>gg' } },
        config = function()
            user.builtin.kbd.noremap(
                { 'n', '<leader>gg', ':Git<CR>' },
                { 'n', '<leader>gs', ':Git stage<CR>' },
                { 'n', '<leader>gc', ':Git commit<CR>' },
                { 'n', '<leader>gp', ':Git push<CR>' })
        end
    },
    {
        'preservim/tagbar',
        config = function()
            user.builtin.kbd.noremap({ 'n', '<C-t>', ':TagbarToggle<CR>', { desc = 'Toggle tagbar' } })
        end
    },
    {
        'lervag/vimtex',
        ft = 'tex',
    },
    {
        'beauwilliams/statusline.lua',
        config = function()
            vim.o.laststatus = 3
        end
    },
    {
        'flazz/vim-colorschemes',
        config = function()
            vim.cmd('colorscheme ' .. user.builtin.colorscheme or user.config.colorscheme )
        end
    },
    {
        'folke/which-key.nvim',
        config = function() user.require('core.packages.configs.which-key_nvim') end
    },
    {
        'iamcco/markdown-preview.nvim',
        ft = 'markdown',
        run = 'cd app && yarn install',
        cmd = 'MarkdownPreview'
    },
    {
        'nvim-treesitter/nvim-treesitter',
        config = function()
            user.require('core.packages.configs.nvim-treesitter')
        end
    },
    { 'nvim-lua/plenary.nvim' },
    { 'tpope/vim-surround' },
    {
        'neovim/nvim-lspconfig',
        requires = {
            { 'lukas-reineke/lsp-format.nvim' },
            { 'SirVer/ultisnips', requires = { { 'honza/vim-snippets' } } },
            { 'folke/trouble.nvim' },
            { "williamboman/mason.nvim" },
            {
                'hrsh7th/nvim-cmp',
                requires = {
                    { 'quangnguyen30192/cmp-nvim-ultisnips' },
                    { 'tamago324/cmp-zsh' },
                    { 'hrsh7th/cmp-buffer' },
                    { 'f3fora/cmp-spell' },
                    { 'hrsh7th/cmp-nvim-lsp' },
                    { 'ray-x/cmp-treesitter' },
                    { 'hrsh7th/cmp-nvim-lua' },
                    { 'hrsh7th/cmp-path' },
                    { 'hrsh7th/cmp-nvim-lsp-signature-help' },
                    { 'hrsh7th/cmp-nvim-lsp-document-symbol' },
                },
            },
        },
        config = function()
            user.require 'core.packages.configs.nvim-lspconfig'
        end,
    },
    {
        'nvim-telescope/telescope.nvim',
        requires = {
            { 'plenary.nvim' },
            { 'nvim-telescope/telescope-file-browser.nvim' },
            { 'nvim-telescope/telescope-project.nvim' },
            { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
        },
        config = function ()
            user.require 'core.packages.configs.telescope_nvim'
        end
    },
    {
        'Raimondi/delimitMate'
    },
}
