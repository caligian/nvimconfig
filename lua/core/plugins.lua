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

    hy = {
        "hylang/vim-hy",
        ft = "hy",
    },

    notify = {
        "rcarriga/nvim-notify",
    },

    signs = {
        "lewis6991/gitsigns.nvim",
        event = 'BufEnter',
    },

    indentblankline = {
        "lukas-reineke/indent-blankline.nvim",
        event = 'InsertEnter'
    },

    align = {
        "junegunn/vim-easy-align",
    },

    suda = {
        "lambdalisue/suda.vim",
    },

    colorscheme = {
        "maxmx03/solarized.nvim",
        dependencies = {
            "RRethy/nvim-base16",
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
        event = "BufEnter",
    },

    clipboard = {
        "jasonccox/vim-wayland-clipboard",
        keys = '"',
        event = "BufEnter",
    },

    startuptime = {
        "dstein64/vim-startuptime",
        config = function()
            kbd.map("ni", "q", "<cmd>hide<CR>", {
                name = "startuptime.hide_buffer",
                event = "FileType",
                pattern = "startuptime",
            })

            kbd.noremap("n", "<leader>hs", "<cmd>StartupTime<CR>", {
                name = "startuptime",
            })
        end,
    },

    comment = {
        "tpope/vim-commentary",
        event = "InsertEnter",
    },

    fennel = {
        "jaawerth/fennel.vim",
        ft = "fennel",
    },

    hop = {
        "phaazon/hop.nvim",
        event = "BufEnter",
    },

    illuminate = { "RRethy/vim-illuminate", event = "InsertEnter" },

    treesitter = {
        "nvim-treesitter/nvim-treesitter",
        event = "InsertEnter",
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
        event = { "BufEnter" },
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
            "onsails/lspkind.nvim",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "tamago324/cmp-zsh",
            "hrsh7th/cmp-nvim-lsp",
            "ray-x/cmp-treesitter",
            "hrsh7th/cmp-nvim-lua",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "hrsh7th/cmp-nvim-lsp-document-symbol",
            "ray-x/navigator.lua",
        },
    },

    fugitive = {
        "tpope/vim-fugitive",
        dependencies = { "tpope/vim-git" },
    },

    tagbar = {
        "preservim/tagbar",
        config = function() kbd.map("n", "<localleader>t", ":TagbarToggle<CR>", { desc = "Tagbar", name = "tagbar" }) end,
        event = "InsertEnter",
    },

    whichkey = {
        "folke/which-key.nvim",
    },

    markdownpreview = {
        "iamcco/markdown-preview.nvim",
        build = "cd app && yarn install",
        ft = "markdown",
    },

    lspsaga = {
        "nvimdev/lspsaga.nvim",
        event = "BufEnter",
    },

    lsp = {
        "neovim/nvim-lspconfig",
        dependencies = {
            "lukas-reineke/lsp-format.nvim",
        },
    },

    undotree = {
        "mbbill/undotree",
        event = "InsertEnter",
    },

    elixir = {
        "elixir-editors/vim-elixir",
        ft = "elixir",
    },

    sexp = {
        "guns/vim-sexp",
        ft = { "lisp", "clojure", "scheme" },
    },
}


