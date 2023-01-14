return {
    {'wbthomason/packer.nvim'},
    {'justinmk/vim-sneak'},
    {'tpope/vim-commentary', keys = {{'v', 'g'}}},
    {
        'tpope/vim-fugitive',
        keys = {{'n', '<leader>gg'}},
        config = function ()
            user.builtin.kbd.noremap(
            {'n', '<leader>gg', ':Git<CR>'},
            {'n', '<leader>gs', ':Git stage<CR>'},
            {'n', '<leader>gc', ':Git commit<CR>'},
            {'n', '<leader>gp', ':Git push<CR>'})
        end
    },
    {
        'preservim/tagbar',
        keys = {{'n', '<C-t>'}},
        config = function ()
            vim.keymap.set('n', '<C-t>', ':TagbarToggle<CR>', {desc='Toggle tagbar'})
        end
    },
    {
        'lervag/vimtex',
        ft = 'tex',
    },
    {
        'vim-airline/vim-airline',
        requires = {{'vim-airline/vim-airline-themes'}},
        config = function ()
            vim.cmd('let g:airline_powerline_fonts = 0')
            vim.cmd('let g:airline#extensions#tabline#enabled = 1')
            vim.cmd("let g:airline#extensions#tabline#formatter = 'unique_tail_improved'")
            vim.cmd('let g:airline_theme = "gotham256"')
        end
    },
    {
        'folke/which-key.nvim',
        keys = {{'n', '<leader>'}},
        config = function () require('core.packages.configs.which-key_nvim') end
    },
    {
        'iamcco/markdown-preview.nvim',
        ft = 'markdown',
        run = 'cd app && yarn install',
        cmd = 'MarkdownPreview'
    },
    {
        'rafi/awesome-vim-colorschemes',
        config = function() vim.cmd('colorscheme gotham256') end

    },
    {
        'nvim-treesitter/nvim-treesitter',
        config = function ()
            require('core.packages.configs.nvim-treesitter')
        end
    },
    { 'nvim-lua/plenary.nvim' },
    { 'tpope/vim-surround' },
    {
        'SirVer/ultisnips',
        requires = {{'honza/vim-snippets'}},
        config = function()
            vim.g.UltiSnipsExpandTrigger = '<C-o>'
            vim.g.UltiSnipsJumpForwardTrigger = '<C-j>'
            vim.g.UltiSnipsJumpBackwardTrigger = '<C-k>'
            vim.g.UltiSnipsEditSplit = 'vertical'
        end
    },

    {
        'neovim/nvim-lspconfig',
        requires = {
            {
                'folke/trouble.nvim',
                config = function()
                    require('trouble').setup {
                        icons=false,
                        fold_open = "v",
                        fold_closed = ">",
                        indent_lines = false,
                        use_diagnostic_signs = false,
                        signs = {
                            error = "Error",
                            warning = "Warn",
                            hint = "Hint",
                            information = "Info",
                            other = "Misc"
                        },
                    }
                    vim.keymap.set("n", "<leader>ltt", "<cmd>TroubleToggle<cr>",
                    {silent = true, noremap = true})
                    vim.keymap.set("n", "<leader>ltw", "<cmd>TroubleToggle workspace_diagnostics<cr>",
                    {silent = true, noremap = true})
                    vim.keymap.set("n", "<leader>ltd", "<cmd>TroubleToggle document_diagnostics<cr>",
                    {silent = true, noremap = true})
                    vim.keymap.set("n", "<leader>ltl", "<cmd>TroubleToggle loclist<cr>",
                    {silent = true, noremap = true})
                    vim.keymap.set("n", "<leader>ltq", "<cmd>TroubleToggle quickfix<cr>",
                    {silent = true, noremap = true})
                    vim.keymap.set("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
                    {silent = true, noremap = true})
                end,
            },
            { "williamboman/mason.nvim", config=function() require('mason').setup() end },
            {
                'hrsh7th/nvim-cmp',
                requires = {
                    {'quangnguyen30192/cmp-nvim-ultisnips'},
                    {'tamago324/cmp-zsh'},
                    {'hrsh7th/cmp-buffer'},
                    {'f3fora/cmp-spell'},
                    {'hrsh7th/cmp-nvim-lsp'},
                    {'ray-x/cmp-treesitter'},
                    {'hrsh7th/cmp-nvim-lua'},
                    {'hrsh7th/cmp-path'},
                    {'hrsh7th/cmp-nvim-lsp-signature-help'},
                    {'hrsh7th/cmp-nvim-lsp-document-symbol'},
                },
            },
        },
        config = function()
            require 'core.packages.configs.nvim-lspconfig'
        end,

    },
    {
        'nvim-telescope/telescope.nvim',
        requires = {
            {'plenary.nvim'},
            {'nvim-telescope/telescope-file-browser.nvim'},
            {'nvim-telescope/telescope-project.nvim'},
            {'nvim-telescope/telescope-fzf-native.nvim', run='make'},
        },
        config = function() require 'core.packages.configs.telescope_nvim' end
    },
    {
        'Raimondi/delimitMate'
    },
}
