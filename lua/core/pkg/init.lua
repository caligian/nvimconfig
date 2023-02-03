Package.defaults = Package.defaults or {}

return require('lazy').setup({
    'wbthomason/packer.nvim',
    'justinmk/vim-sneak',
    'Raimondi/delimitMate',
    'nvim-lua/plenary.nvim',
    'beauwilliams/statusline.lua',
    'tpope/vim-surround',

    {'jasonccox/vim-wayland-clipboard', keys = '"'},

    { 'dstein64/vim-startuptime', cmd = 'StartupTime'},

    { 'dracula/vim', name = 'dracula' },

    { 'tpope/vim-commentary', keys = 'g' },

    { 'lervag/vimtex', ft = 'tex' },

    { 'jaawerth/fennel.vim', ft = 'fennel' },

    {
        'Olical/conjure',
        ft = {
            'clojure',
            'fennel',
            'common-lisp',
            'guile',
            'hy',
            'janet',
            'julia',
            'lua',
            'python',
            'racket',
            'rust',
            'scheme',
        },
    },

    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        dependencies = { 'nvim-treesitter/nvim-treesitter' }
    },

    {
        'RRethy/nvim-treesitter-textsubjects',
        dependencies = { 'nvim-treesitter/nvim-treesitter' }
    },

    {
        'nvim-treesitter/nvim-treesitter',
        config = function()
            require 'core.pkg.configs.nvim-treesitter'
        end
    },


    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            { 'honza/vim-snippets' },
            { 'SirVer/ultisnips' },
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

    {
        'tpope/vim-fugitive',
        keys = '<leader>g',
        config = function()
            Keybinding({ noremap = true, leader = true, mode = 'n' }):bind {
                { 'gg', ':Git<CR>' },
                { 'gs', ':Git stage <CR>' },
                { 'gc', ':Git commit <CR>' },
            }
        end,
    },

    {
        'preservim/tagbar',
        keys = '<C-t>',
        config = function()
            Keybinding.noremap('n', '<C-t>', ':TagbarToggle<CR>', { desc = 'Toggle tagbar' })
        end
    },

    {
        'flazz/vim-colorschemes',
        config = function()
            vim.cmd('colorscheme ' .. user.colorscheme)
        end
    },

    {
        'folke/which-key.nvim',
        config = function()
            builtin.require 'core.pkg.configs.which-key_nvim'
        end
    },

    {
        'iamcco/markdown-preview.nvim',
        build = 'cd app && yarn install',
        ft = 'markdown',
    },

    {
        'neovim/nvim-lspconfig',
        dependencies = {
            { 'lukas-reineke/lsp-format.nvim' },
            { 'SirVer/ultisnips' },
            { 'folke/trouble.nvim' },
            { "williamboman/mason.nvim" },
            { 'hrsh7th/nvim-cmp' },
        },
        config = function()
            builtin.require 'core.pkg.configs.nvim-lspconfig'
        end,
        lazy = false,
    },

    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            { 'hrsh7th/nvim-cmp' },
            { 'nvim-telescope/telescope-file-browser.nvim' },
            { 'nvim-telescope/telescope-project.nvim' },
            { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
        },
        config = function()
            builtin.require 'core.pkg.configs.telescope_nvim'
        end,
        lazy = false,
    },

    {
        'moll/vim-bbye',
        config = function()
            Keybinding({ noremap = true, leader = true }):bind {
                { 'bq', 'Bdelete', { desc = 'Delete buffer' } },
                { 'bQ', 'Bwipeout', { desc = 'Wipeout buffer' } }
            }
        end,
        lazy = false,
    },
}, { lazy = true })
