local default = {
  statusline = {
    "nvim-lualine/lualine.nvim",
    priority = 1000,
  },

  neorg = {
    "nvim-neorg/neorg",
    ft = "norg",
  },

  plenary = { "nvim-lua/plenary.nvim" },

  telescope = {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-project.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
  },

  spectre = {
    "nvim-pack/nvim-spectre",
    event = "InsertEnter",
  },

  hy = {
    "hylang/vim-hy",
    ft = "hy",
  },

  notify = {
    "rcarriga/nvim-notify",
    event = "BufRead",
  },

  signs = {
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
  },

  indentblankline = {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufRead",
  },

  align = {
    "junegunn/vim-easy-align",
    event = "InsertEnter",
  },

  suda = {
    "lambdalisue/suda.vim",
    event = "BufRead",
  },

  colorscheme = {
    "sainnhe/everforest",
    dependencies = {
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
    priority = 3000,
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
    event = "BufRead",
  },

  surround = {
    "kylechui/nvim-surround",
    event = "BufRead",
  },

  autopairs = {
    "windwp/nvim-autopairs",
    event = "BufRead",
  },

  clipboard = {
    "jasonccox/vim-wayland-clipboard",
    keys = '"',
  },

  startuptime = {
    "dstein64/vim-startuptime",
    config = function()
      Kbd.map("ni", "q", "<cmd>hide<CR>", {
        name = "startuptime.hide_buffer",
        event = "FileType",
        pattern = "startuptime",
      })

      Kbd.noremap("n", "<leader>hs", "<cmd>StartupTime<CR>", {
        name = "startuptime",
      })
    end,
  },

  comment = {
    "tpope/vim-commentary",
    event = "BufRead",
  },

  fennel = {
    "jaawerth/fennel.vim",
    ft = "fennel",
  },

  hop = {
    "phaazon/hop.nvim",
    event = "BufRead",
  },

  illuminate = {
    "RRethy/vim-illuminate",
    event = "BufRead",
  },

  treesitter = {
    "nvim-treesitter/nvim-treesitter",

    dependencies = {
      "windwp/nvim-autopairs",
      "RRethy/vim-illuminate",
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
      "kiyoon/treesitter-indent-object.nvim",
      "nvim-treesitter/nvim-treesitter-refactor",
      "MunifTanjim/nui.nvim",
    },

    event = "BufReadPost",
  },

  hop = {
    "mfussenegger/nvim-treehopper",
    dependencies = { "phaazon/hop.nvim" },
    event = { "InsertEnter" },
  },

  snippets = {
    "L3MON4D3/LuaSnip",
    event = "BufRead",
    dependencies = { "rafamadriz/friendly-snippets" },
  },

  cmp = {
    "hrsh7th/nvim-cmp",
    event = "BufRead",
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
    config = function()
      Kbd.map("n", "<localleader>t", ":TagbarToggle<CR>", { desc = "Tagbar", name = "tagbar" })
    end,
    event = "BufRead",
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
    event = "BufRead",
  },

  lsp = {
    "neovim/nvim-lspconfig",
    dependencies = {
      "lukas-reineke/lsp-format.nvim",
      { "folke/neodev.nvim", opts = {} },
    },
    event = "BufReadPost",
  },

  undotree = {
    "mbbill/undotree",
    event = "BufReadPost",
  },

  elixir = {
    "elixir-editors/vim-elixir",
    ft = "elixir",
  },
}

if req2path "user.plugins" then
  local spec = requirex "user.string"
  if is_table(spec) then
    dict.merge(default, { spec })
  end
end

return default
