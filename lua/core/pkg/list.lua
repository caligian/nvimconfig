return {
    { 'wbthomason/packer.nvim' },
    { 'jaawerth/fennel.vim' },
    { 'Olical/conjure' },
    { 'justinmk/vim-sneak' },
    { 'Raimondi/delimitMate' },
    { 'tpope/vim-commentary' },
    { 'nvim-lua/plenary.nvim' },
    { 'tpope/vim-surround' },
    { 'jasonccox/vim-wayland-clipboard' },
    { 'beauwilliams/statusline.lua' },
    {
        'tpope/vim-fugitive',
        keys = { { 'n', '<leader>gg' } },
        config = function()
            user.kbd.noremap(
                { 'n', '<leader>gg', ':Git<CR>' },
                { 'n', '<leader>gs', ':Git stage<CR>' },
                { 'n', '<leader>gc', ':Git commit<CR>' },
                { 'n', '<leader>gp', ':Git push<CR>' })
        end
    },
    {
        'preservim/tagbar',
        config = function()
            user.kbd.noremap({ 'n', '<C-t>', ':TagbarToggle<CR>', { desc = 'Toggle tagbar' } })
        end
    },
    {
        'lervag/vimtex',
        ft = 'tex',
    },
    {
        'flazz/vim-colorschemes',
        config = function()
            vim.cmd('colorscheme ' .. user.colorscheme or user.config.colorscheme)
        end
    },
    {
        'folke/which-key.nvim',
        config = function()
            builtin.require('core.pkg.configs.which-key_nvim')
        end
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
            builtin.require('core.pkg.configs.nvim-treesitter')
        end
    },
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
            builtin.require 'core.pkg.configs.nvim-lspconfig'
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
        config = function()
            builtin.require 'core.pkg.configs.telescope_nvim'
            builtin.require 'core.pkg.configs.telescope_nvim.keybindings'
        end
    },
}
