--------------------------------------------------------------------------------

plugin "statusline" {
  "nvim-lualine/lualine.nvim",
}

plugin "plenary" {
  "nvim-lua/plenary.nvim",
}

plugin "telescope" {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-telescope/telescope-fzy-native.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
  },
}

plugin "dispatch" {
  "tpope/vim-dispatch",
  event = "BufReadPost",
}

plugin "hy" {
  "hylang/vim-hy",
  ft = { "hy" },
}

plugin "notify" {
  "rcarriga/nvim-notify",
}

plugin "gitsigns" {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPost",
}

plugin "indentblankline" {
  "lukas-reineke/indent-blankline.nvim",
  event = "BufReadPost",
}

plugin "align" {
  "junegunn/vim-easy-align",
  event = "BufReadPost",
}

plugin "neorg" {
  "nvim-neorg/neorg",
  ft = "norg",
}

plugin "suda" {
  "lambdalisue/suda.vim",
}

-- Good opinionated themes
plugin "colorscheme" {
  "sainnhe/everforest",

  dependencies = {
    "maxmx03/solarized.nvim",
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
}

plugin "vimtex" {
  "lervag/vimtex",
  ft = "tex",
}

plugin "devicons" {
  "nvim-tree/nvim-web-devicons",
}

plugin "netrw" {
  "prichrd/netrw.nvim",
  cmd = "Lexplore",
}

plugin "surround" {
  "kylechui/nvim-surround",
  event = "InsertEnter",
}

plugin "autopairs" {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
}

plugin "lint" {
  "mfussenegger/nvim-lint",
  event = "BufReadPost",
}

plugin "vim-wayland-clipboard" {
  "jasonccox/vim-wayland-clipboard",
  keys = '"',
}

plugin "startuptime" {
  "dstein64/vim-startuptime",
  cmd = "StartupTime",
  config = function()
    Autocmd("FileType", {
      pattern = "startuptime",
      callback = function()
        vim.keymap.set(
          { "n", "i" },
          "q",
          ":bwipeout % <bar> :b# <CR>",
          { buffer = vim.fn.bufnr() }
        )
      end,
    })
  end,
}

plugin "comment" {
  "tpope/vim-commentary",
  event = "BufReadPost",
}

plugin "vimtex" {
  "lervag/vimtex",
  ft = "tex",
}

plugin "fennel" {
  "jaawerth/fennel.vim",
  ft = "fennel",
}

plugin "ssr" {
  "cshuaimin/ssr.nvim",
  event = "BufReadPost",
}

plugin "hop" {
  "phaazon/hop.nvim",
  event = 'WinEnter',
}

plugin "treesitter" {
  "nvim-treesitter/nvim-treesitter",
  event = "BufReadPost",
  dependencies = {
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
    "andymass/vim-matchup",
    "cshuaimin/ssr.nvim",
    "nvim-treesitter/nvim-treesitter-refactor",
    "MunifTanjim/nui.nvim",
  },
}

plugin 'snippets' {
  'L3MON4D3/LuaSnip',
  dependencies = { "rafamadriz/friendly-snippets" },
  event = 'InsertEnter',
}

plugin "cmp" {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    "tamago324/cmp-zsh",
    "hrsh7th/cmp-nvim-lsp",
    "ray-x/cmp-treesitter",
    "hrsh7th/cmp-nvim-lua",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp-signature-help",
    "hrsh7th/cmp-nvim-lsp-document-symbol",
  },
}

plugin "fugitive" {
  "tpope/vim-fugitive",
  dependencies = { "tpope/vim-git" },
  keys = {
    { "<leader>gs", ":Git stage %<CR>", "n", { desc = "Stage buffer" } },
    { "<leader>gc", ":Git commit <CR>", "n", { desc = "Commit buffer" } },
    { "<leader>gg", ":tab Git<CR>", "n", { desc = "Open Fugitive" } },
  },
}

plugin "tagbar" {
  "preservim/tagbar",
  keys = "<C-t>",
  event = "BufReadPost",
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
}

plugin "whichkey" {
  "folke/which-key.nvim",
}

plugin "markdownpreview" {
  "iamcco/markdown-preview.nvim",
  build = "cd app && yarn install",
  ft = "markdown",
}

plugin "formatter" {
  "mhartington/formatter.nvim",
  event = "BufReadPost",
}

plugin "lsp" {
  "neovim/nvim-lspconfig",
  dependencies = {
    "j-hui/fidget.nvim",
    "lukas-reineke/lsp-format.nvim",
    "williamboman/mason.nvim",
    "mfussenegger/nvim-dap",
  },
}

plugin "bbye" {
  "moll/vim-bbye",
  event = "BufReadPost",
}
