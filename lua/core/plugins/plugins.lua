return {
  { "nvim-lua/plenary.nvim" },

  { "hylang/vim-hy", ft = { "hy" } },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufEnter",
    config = function()
      local indent = req "indent_blankline"
      indent.setup {
        -- for example, context is off by default, use this to turn it on
        show_current_context = false,
        show_current_context_start = false,
      }
    end,
  },

  {
    "nvim-neorg/neorg",
    ft = "norg",
    config = function()
      req "core.plugins.neorg"
    end,
  },

  {
    "junegunn/vim-easy-align",
    event = "BufReadPre",
    config = function()
      Keybinding.noremap("n", "<leader>=", ":EasyAlign ", { desc = "Align lines" })
    end,
  },

  {
    "lambdalisue/suda.vim",
    config = function()
      vim.g.suda_smart_edit = 1
    end,
  },

  -- Good opinionated themes
  {
    "sainnhe/everforest",
    -- A hack to ensure that user.colorscheme is captured
    dependencies = {
      { "rktjmp/lush.nvim" },
      { "rose-pine/neovim" },
      { "navarasu/onedark.nvim" },
      { "Shatur/neovim-ayu" },
      { "svrana/neosolarized.nvim" },
      { "mcchrish/zenbones.nvim" },
      { "tjdevries/colorbuddy.nvim" },
      { "jesseleite/nvim-noirbuddy" },
      { "ray-x/starry.nvim" },
      { "catppuccin/nvim" },
      { "marko-cerovac/material.nvim" },
      { "fenetikm/falcon" },
      { "shaunsingh/nord.nvim" },
      { "rebelot/kanagawa.nvim" },
      { "EdenEast/nightfox.nvim" },
      { "projekt0n/github-nvim-theme" },
      { "bluz71/vim-nightfly-colors" },
      { "bluz71/vim-moonfly-colors" },
      { "folke/lsp-colors.nvim" },
      { "savq/melange-nvim" },
      { "AlexvZyl/nordic.nvim" },
      { "mhartington/oceanic-next" },
      { "folke/tokyonight.nvim" },
    },
    config = function()
      req "core.plugins.colorscheme"
      -- vim.cmd("color github_dark")
    end,
  },

  {
    "lervag/vimtex",
    config = function()
      req "core.plugins.vimtex"
    end,
    ft = "tex",
  },

  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      local web = req "nvim-web-devicons"
      if web then
        web.setup {}
      end
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    event = "VimEnter",
    config = function()
      req "core.plugins.nvim-tree"
    end,
  },

  { "tpope/vim-surround", event = "InsertEnter", dependencies = { "tpope/vim-repeat" } },

  { "justinmk/vim-sneak", event = "InsertEnter" },

  { "Raimondi/delimitMate", event = "InsertEnter" },

  {
    "mfussenegger/nvim-lint",
    event = "BufReadPost",
    config = function()
      req "core.plugins.nvim-lint"
    end,
  },

  { "jasonccox/vim-wayland-clipboard", keys = '"' },

  { "dstein64/vim-startuptime", cmd = "StartupTime" },

  { "tpope/vim-commentary", keys = "g" },

  { "lervag/vimtex", ft = "tex" },

  { "jaawerth/fennel.vim", ft = "fennel" },

  {
    "Olical/conjure",
    ft = user.conjure_langs,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = "InsertEnter",
    dependencies = {
      "RRethy/nvim-treesitter-textsubjects",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      req "core.plugins.nvim-treesitter"
    end,
  },

  {
    "SirVer/ultisnips",
    event = "InsertEnter",
    dependencies = { { "honza/vim-snippets" } },
    config = function()
      req "core.plugins.ultisnips"
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      { "quangnguyen30192/cmp-nvim-ultisnips" },
      { "tamago324/cmp-zsh" },
      { "f3fora/cmp-spell" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "ray-x/cmp-treesitter" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-nvim-lsp-signature-help" },
      { "hrsh7th/cmp-nvim-lsp-document-symbol" },
    },
    config = function()
      req "core.plugins.nvim-cmp"
    end,
  },

  {
    "tpope/vim-fugitive",
    config = function()
      req "core.plugins.vim-fugitive"
    end,
  },

  {
    "preservim/tagbar",
    keys = "<C-t>",
    event = "BufEnter",
    config = function()
      Keybinding.noremap(
        "n",
        "<C-t>",
        ":TagbarToggle<CR>",
        { desc = "Toggle tagbar", name = "tagbar" }
      )
      vim.g.tagbar_position = "leftabove vertical"
      req "user.plugins.tagbar"
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VimEnter",
    config = function()
      req "core.plugins.which-key"
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && yarn install",
    ft = "markdown",
  },

  {
    "mhartington/formatter.nvim",
    event = "BufReadPost",
    config = function()
      req "core.plugins.formatter"
    end,
  },

  {
    "neovim/nvim-lspconfig",
    ft = grep(keys(Lang.langs), function(k)
      if haskey(Lang.langs, k, "server") then
        return k
      end
    end),
    dependencies = {
      { "lukas-reineke/lsp-format.nvim" },
      { "williamboman/mason.nvim" },
    },
    config = function()
      req "core.plugins.nvim-lspconfig"
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-telescope/telescope-file-browser.nvim" },
      { "nvim-telescope/telescope-project.nvim" },
      { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
    },
    config = function()
      req "core.plugins.telescope"
    end,
    event = "VimEnter",
  },

  {
    "moll/vim-bbye",
    event = "BufReadPre",
    config = function()
      Keybinding.bind(
        { noremap = true, leader = true },
        { "bq", "<cmd>Bdelete<CR>", { desc = "Delete buffer" } },
        { "bQ", "<cmd>Bwipeout<CR>", { desc = "Wipeout buffer" } }
      )
      req "user.plugins.vim-bbye"
    end,
  },
}
