return {
    statusline = {
        "nvim-lualine/lualine.nvim",
    },

    plenary = {
        "nvim-lua/plenary.nvim",
    },

    telescope = {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-telescope/telescope-fzy-native.nvim",
            "nvim-telescope/telescope-file-browser.nvim",
        },
    },

    dispatch = {
        "tpope/vim-dispatch",
        event = "BufReadPost",
    },

    hy = {
        "hylang/vim-hy",
        ft = { "hy" },
    },

    notify = {
        "rcarriga/nvim-notify",
    },

    signs = {
        "lewis6991/gitsigns.nvim",
        event = "BufReadPost",
    },

    indentblankline = {
        "lukas-reineke/indent-blankline.nvim",
        event = "BufReadPost",
    },

    align = {
        "junegunn/vim-easy-align",
        event = "BufReadPost",
    },

    neorg = {
        "nvim-neorg/neorg",
        ft = "norg",
    },

    suda = {
        "lambdalisue/suda.vim",
        event = 'BufRead',
    },

    colorscheme = {
        "RRethy/nvim-base16",
        dependencies = {
            "maxmx03/solarized.nvim",
            "sainnhe/everforest",
            "rktjmp/lush.nvim",
            "rose-pine/neovim",
            "navarasu/onedark.nvim",
            "Shatur/neovim-ayu",
            "mcchrish/zenbones.nvim",
            "tjdevries/colorbuddy.nvim",
            "jesseleite/nvim-noirbuddy",
            "ray-x/starry.nvim",
            "catppuccin/nvim",
            "marko-cerovac/material.nvim",
            "fenetikm/falcon",
            "shaunsingh/nord.nvim",
            "rebelot/kanagawa.nvim",
            "EdenEast/nightfox.nvim",
            "projekt0n/github-nvim-theme",
            "bluz71/vim-nightfly-colors",
            "bluz71/vim-moonfly-colors",
            "folke/lsp-colors.nvim",
            "savq/melange-nvim",
            "AlexvZyl/nordic.nvim",
            "mhartington/oceanic-next",
            "folke/tokyonight.nvim",
        },
        priority = 300,
    },

    vimtex = {
        "lervag/vimtex",
        ft = "tex",
    },

    devicons = {
        "nvim-tree/nvim-web-devicons",
    },

    netrw = {
        "prichrd/netrw.nvim",
    },

    surround = {
        "kylechui/nvim-surround",
        event = "InsertEnter",
    },

    autopairs = {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
    },

    lint = {
        "mfussenegger/nvim-lint",
        event = "BufReadPost",
    },

    clipboard = {
        "jasonccox/vim-wayland-clipboard",
        keys = '"',
    },

    startuptime = {
        "dstein64/vim-startuptime",
        config = function ()
            kbd.map(
                'ni',
                'q',
                '<cmd>hide<CR>',
                {
                    name = 'startuptime.hide_buffer',
                    event = 'FileType',
                    pattern = 'startuptime'
                }
            )

            kbd.noremap(
                'n',
                '<leader>hs',
                '<cmd>StartupTime<CR>',
                {
                    name = 'startuptime',
                }
            )
        end
    },

    comment = {
        "tpope/vim-commentary",
    },

    vimtex = {
        "lervag/vimtex",
        ft = "tex",
    },

    fennel = {
        "jaawerth/fennel.vim",
        ft = "fennel",
    },

    ssr = {
        "cshuaimin/ssr.nvim",
        event = "BufReadPost",
    },

    hop = {
        "phaazon/hop.nvim",
        event = "WinEnter",
    },

    illuminate = { "RRethy/vim-illuminate", event = "BufReadPost" },

    treesitter = {
        "nvim-treesitter/nvim-treesitter",
        event = "BufReadPost",
        dependencies = {
            "windwp/nvim-autopairs",
            "RRethy/vim-illuminate",
            "RRethy/nvim-treesitter-textsubjects",
            "nvim-treesitter/nvim-treesitter-textobjects",
            {
                "kiyoon/treesitter-indent-object.nvim",
                keys = {
                    {
                        "ai",
                        "<Cmd>lua require'treesitter_indent_object.textobj'.select_indent_outer()<CR>",
                        mode = { "x", "o" },
                        desc = "Select indent (outer)",
                    },
                    {
                        "aI",
                        "<Cmd>lua require'treesitter_indent_object.textobj'.select_indent_outer(true)<CR>",
                        mode = { "x", "o" },
                        desc = "Select indent (outer, line-wise)",
                    },
                    {
                        "ii",
                        "<Cmd>lua require'treesitter_indent_object.textobj'.select_indent_inner()<CR>",
                        mode = { "x", "o" },
                        desc = "Select indent (inner, partial range)",
                    },
                    {
                        "iI",
                        "<Cmd>lua require'treesitter_indent_object.textobj'.select_indent_inner(true)<CR>",
                        mode = { "x", "o" },
                        desc = "Select indent (inner, entire range)",
                    },
                },
                event = "BufReadPost",
            },
            {
                "mfussenegger/nvim-treehopper",
                dependencies = { "phaazon/hop.nvim" },
            },
            "kiyoon/treesitter-indent-object.nvim",
            "cshuaimin/ssr.nvim",
            "nvim-treesitter/nvim-treesitter-refactor",
            "MunifTanjim/nui.nvim",
        },
    },

    treehopper = {
        "mfussenegger/nvim-treehopper",
        dependencies = { "phaazon/hop.nvim" },
        event = { "BufReadPost" },
    },

    snippets = {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
        event = "InsertEnter",
    },

    cmp = {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "tamago324/cmp-zsh",
            "hrsh7th/cmp-nvim-lsp",
            "ray-x/cmp-treesitter",
            "hrsh7th/cmp-nvim-lua",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "hrsh7th/cmp-nvim-lsp-document-symbol",
        },
    },

    fugitive = {
        "tpope/vim-fugitive",
        dependencies = { "tpope/vim-git" },
    },

    tagbar = {
        "preservim/tagbar",
        config = function ()
            kbd.map('n', '<localleader>t', ':TagbarToggle<CR>', {desc = 'Tagbar', name = 'tagbar'})
        end
    },

    whichkey = {
        "folke/which-key.nvim",
    },

    markdownpreview = {
        "iamcco/markdown-preview.nvim",
        build = "cd app && yarn install",
        ft = "markdown",
    },

    lsp = {
        "neovim/nvim-lspconfig",
        dependencies = { "lukas-reineke/lsp-format.nvim", },
    },

    undotree = {
        "mbbill/undotree",
        event = "InsertEnter",
    },

    bufferline = {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "tiagovla/scope.nvim" },
    },

    elixir = {
        "elixir-editors/vim-elixir",
        ft = "elixir",
    },

    sexp = {
        'guns/vim-sexp',
        ft = {'lisp', 'clojure', 'scheme'},
    },
}
