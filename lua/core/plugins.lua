plugin.statusline.spec = {
  "nvim-lualine/lualine.nvim",
}

plugin.plenary.spec = {
  "nvim-lua/plenary.nvim",
}

plugin.telescope.spec = {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-telescope/telescope-fzy-native.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
  },
}

plugin.dispatch.spec = {
  "tpope/vim-dispatch",
  event = "BufReadPost",
}

plugin.hy.spec = {
  "hylang/vim-hy",
  ft = { "hy" },
}

plugin.notify.spec = {
  "rcarriga/nvim-notify",
}

plugin.gitsigns.spec = {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPost",
}

plugin.indentblankline.spec = {
  "lukas-reineke/indent-blankline.nvim",
  event = "BufReadPost",
}

plugin.align.spec = {
  "junegunn/vim-easy-align",
  event = "BufReadPost",
}

plugin.neorg.spec = {
  "nvim-neorg/neorg",
  ft = "norg",
}

plugin.suda.spec = {
  "lambdalisue/suda.vim",
}

plugin.colorscheme.spec = {
  "maxmx03/solarized.nvim",

  dependencies = {
    "RRethy/nvim-base16",
    "sainnhe/everforest",
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

plugin.vimtex.spec = {
  "lervag/vimtex",
  ft = "tex",
}

plugin.devicons.spec = {
  "nvim-tree/nvim-web-devicons",
}

plugin.netrw.spec = {
  "prichrd/netrw.nvim",
}

plugin.surround.spec = {
  "kylechui/nvim-surround",
  event = "InsertEnter",
}

plugin.autopairs.spec = {
  "windwp/nvim-autopairs",
  event = 'InsertEnter',
}

plugin.lint.spec = {
  "mfussenegger/nvim-lint",
  event = "BufReadPost",
}

plugin.clipboard.spec = {
  "jasonccox/vim-wayland-clipboard",
  keys = '"',
}

plugin.startuptime.spec = {
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

plugin.comment.spec = {
  "tpope/vim-commentary",
  event = "BufReadPost",
}

plugin.vimtex.spec = {
  "lervag/vimtex",
  ft = "tex",
}

plugin.fennel.spec = {
  "jaawerth/fennel.vim",
  ft = "fennel",
}

plugin.ssr.spec = {
  "cshuaimin/ssr.nvim",
  event = "BufReadPost",
}

plugin.hop.spec = {
  "phaazon/hop.nvim",
  event = "WinEnter",
}

plugin.treesitter.spec = {
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
}

plugin["treesitter-indent-object.nvim"].spec = {
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
}

plugin.treehopper.spec = {
  "mfussenegger/nvim-treehopper",
  dependencies = { "phaazon/hop.nvim" },
  event = { 'BufReadPost' }
}

plugin.snippets.spec = {
  "L3MON4D3/LuaSnip",
  dependencies = { "rafamadriz/friendly-snippets" },
  event = "InsertEnter",
}

plugin.cmp.spec = {
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
}

plugin.fugitive = {
  spec = {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-git" },
  },
  kbd = {
    leader = true,
    { "gs", ":Git stage %<CR>", { desc = "Stage buffer" } },
    { "gc", ":Git commit <CR>", { desc = "Commit buffer" } },
    { "gg", ":tab Git<CR>",     { desc = "Open Fugitive" } },
  },
}

plugin.tagbar.spec = {
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

plugin.whichkey.spec = {
  "folke/which-key.nvim",
}

plugin.markdownpreview.spec = {
  "iamcco/markdown-preview.nvim",
  build = "cd app && yarn install",
  ft = "markdown",
}

plugin.lsp.spec = {
  "neovim/nvim-lspconfig",
  dependencies = {
    "j-hui/fidget.nvim",
    "lukas-reineke/lsp-format.nvim",
    "mfussenegger/nvim-dap",
  },
}

plugin.bbye.spec = {
  "moll/vim-bbye",
  event = "BufReadPost",
}

plugin.undotree.spec = {
  "mbbill/undotree",
  event = "InsertEnter",
}

plugin.scope.spec = {
  "tiagovla/scope.nvim",
}

plugin.bufferline.spec = {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "tiagovla/scope.nvim" },
}
