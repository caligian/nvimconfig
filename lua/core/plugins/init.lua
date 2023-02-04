return require('lazy').setup({
    'justinmk/vim-sneak',
    'Raimondi/delimitMate',
    'nvim-lua/plenary.nvim',
    'beauwilliams/statusline.lua',
    'tpope/vim-surround',

    {
        'elihunter173/dirbuf.nvim',
        keys = '<C-c>',
        config = function()
            Package.defaults['dirbuf.nvim'] = {
                hash_padding = 2,
                show_hidden = true,
                sort_order = "default",
                write_cmd = "DirbufSync",
            }
            V.require 'user.plugins.dirbuf_nvim'
            require('dirbuf').setup(Package.defaults['dirbuf.nvim'])

            Keybinding.noremap('n', '<C-c>d', '<cmd>Dirbuf<CR>', { desc = 'Open current directory' })
        end,
    },

    { 'jasonccox/vim-wayland-clipboard', keys = '"' },

    { 'dstein64/vim-startuptime', cmd = 'StartupTime' },

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
        'nvim-treesitter/nvim-treesitter',
        event = 'InsertEnter',
        dependencies = { 'RRethy/nvim-treesitter-textsubjects', 'nvim-treesitter/nvim-treesitter-textobjects' },
        config = function()
            require 'core.plugins.nvim-treesitter'
        end
    },


    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
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
        event = 'VimEnter',
        config = function()
            V.require 'core.plugins.which-key_nvim'
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
            V.require 'core.plugins.nvim-lspconfig'
        end,
    },

    {
        'nvim-telescope/telescope.nvim',
        event = 'VimEnter',
        dependencies = {
            { 'hrsh7th/nvim-cmp' },
            { 'nvim-telescope/telescope-file-browser.nvim' },
            { 'nvim-telescope/telescope-project.nvim' },
            { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
        },
        config = function()
            V.require 'core.plugins.telescope_nvim'
        end,
    },

    {
        'moll/vim-bbye',
        event = 'BufCreate',
        config = function()
            Keybinding({ noremap = true, leader = true }):bind {
                { 'bq', 'Bdelete', { desc = 'Delete buffer' } },
                { 'bQ', 'Bwipeout', { desc = 'Wipeout buffer' } }
            }
        end,
    },
}, { lazy = true })
