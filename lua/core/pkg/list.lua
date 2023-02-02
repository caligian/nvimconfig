local P = Package

P 'wbthomason/packer.nvim'
P 'Olical/conjure'
P 'jaawerth/fennel.vim'
P 'justinmk/vim-sneak'
P 'Raimondi/delimitMate'
P 'tpope/vim-commentary'
P 'nvim-lua/plenary.lua'
P 'jasonccox/vim-wayland-clipboard'
P 'beauwilliams/statusline.lua'
P 'lukas-reineke/lsp-format.nvim'
P 'honza/vim-snippets'
P 'SirVer/ultisnips'
P 'folke/trouble.nvim'
P 'williamboman/mason.nvim'
P 'hrsh7th/nvim-cmp'
P 'quangnguyen30192/cmp-nvim-ultisnips'
P 'tamago324/cmp-zsh'
P 'hrsh7th/cmp-buffer'
P 'f3fora/cmp-spell'
P 'hrsh7th/cmp-nvim-lsp'
P 'ray-x/cmp-treesitter'
P 'hrsh7th/cmp-nvim-lua'
P 'hrsh7th/cmp-path'
P 'hrsh7th/cmp-nvim-lsp-signature-help'
P 'hrsh7th/cmp-nvim-lsp-document-symbol'
P 'nvim-telescope/telescope-file-browser.nvim'
P 'nvim-telescope/telescope-project.nvim'
P 'nvim-telescope/telescope-fzf-native.nvim'

P('nvim-treesitter/nvim-treesitter'):setup {
    config = function()
        require 'core.pkg.configs.nvim-treesitter'
    end
}

P('lervag/vimtex'):setup { ft = 'tex' }

P('hrsh7th/nvim-cmp'):setup {
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
    }
}

P('tpope/vim-fugitive'):setup {
    config = function()
        user.kbd({ noremap = true, leader = true, mode = 'n' }):bind {
            { 'gg', ':Git<CR>' },
            { 'gs', ':Git stage <CR>' },
            { 'gc', ':Git commit <CR>' },
        }
    end,
}

P('preservim/tagbar'):setup {
    config = function()
        user.kbd.noremap('n', '<C-t>', ':TagbarToggle<CR>', { desc = 'Toggle tagbar' })
    end
}

P('flazz/vim-colorschemes'):setup {
    config = function()
        vim.cmd('colorscheme ' .. user.colorscheme)
    end
}

P('folke/which-key.nvim'):setup {
    config = function()
        builtin.require 'core.pkg.configs.which-key_nvim'
    end
}

P('iamcco/markdown-preview.nvim'):setup {
    run = 'cd app && yarn install',
}

P('neovim/nvim-lspconfig'):setup {
    requires = {
        { 'lukas-reineke/lsp-format.nvim' },
        { 'SirVer/ultisnips' },
        { 'folke/trouble.nvim' },
        { "williamboman/mason.nvim" },
        { 'hrsh7th/nvim-cmp' },
    },
    config = function()
        builtin.require 'core.pkg.configs.nvim-lspconfig'
    end
}

P('nvim-telescope/telescope.nvim'):setup {
    requires = {
        { 'plenary.nvim' },
        { 'nvim-telescope/telescope-file-browser.nvim' },
        { 'nvim-telescope/telescope-project.nvim' },
        { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    },
    config = function()
        builtin.require 'core.pkg.configs.telescope_nvim'
    end
}
