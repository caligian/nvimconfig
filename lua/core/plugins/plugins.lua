return {
  { "nvim-lua/plenary.nvim" },

  { "nathom/filetype.nvim" },

  { "Konfekt/vim-compilers", event = "BufEnter" },

  { "hylang/vim-hy", ft = { "hy" } },

  { "mfussenegger/nvim-fzy" },

  { "rcarriga/nvim-notify" },

  {
    "krady21/compiler-explorer.nvim",
    event = "BufReadPost",
    config = function() req "user.plugins.compiler" end,
  },

  {
    "RRethy/vim-illuminate",
    config = function() req "user.plugins.illuminate" end,
    event = "BufReadPre",
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "rcarriga/nvim-notify",
      {'akinsho/bufferline.nvim', tag = 'v3.5.0'}
    },
    config = function() req "core.plugins.statusline" end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    config = function() req "core.plugins.gitsigns" end,
  },

  {
    "dhruvasagar/vim-buffer-history",
    event = "BufEnter",
    config = function()
      K.bind({ noremap = true, leader = true }, {
        "bN",
        "<Plug>(buffer-history-forward)",
        "Next buffer in history",
      }, {
        "bP",
        "<Plug>(buffer-history-back)",
        "Previous buffer in history",
      }, {
        "bh",
        "<Plug>(buffer-history-list)",
        "Show buffer history",
      })
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    config = function() req "core.plugins.indent-blankline" end,
  },

  {
    "nvim-neorg/neorg",
    ft = "norg",
    config = function() req "core.plugins.neorg" end,
  },

  {
    "junegunn/vim-easy-align",
    event = "BufReadPost",
    config = function()
      Keybinding.noremap(
        "n",
        "<leader>=",
        ":EasyAlign ",
        { desc = "Align lines" }
      )
      Keybinding.noremap(
        "v",
        "<leader>=",
        ":'<,'>EasyAlign ",
        { desc = "Align lines" }
      )
    end,
  },

  {
    "lambdalisue/suda.vim",
    cmd = "SudaRead",
    config = function() vim.g.suda_smart_edit = 1 end,
  },

  -- Good opinionated themes
  {
    "sainnhe/everforest",
    -- A hack to ensure that all colorschemes are loaded at once
    dependencies = {
      "mfussenegger/nvim-fzy",
      "rktjmp/lush.nvim",
      "rose-pine/neovim",
      "navarasu/onedark.nvim",
      "Shatur/neovim-ayu",
      "svrana/neosolarized.nvim",
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
    config = function() req "core.plugins.colorscheme" end,
  },

  {
    "lervag/vimtex",
    config = function() req "core.plugins.vimtex" end,
    ft = "tex",
  },

  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      local web = req "nvim-web-devicons"
      if web then web.setup {} end
    end,
  },

  {
    "prichrd/netrw.nvim",
    cmd = "Lexplore",
    config = function()
      utils.log_pcall(
        function()
          require("netrw").setup {
            icons = {
              symlink = "",
              directory = "",
              file = "",
            },
            use_devicons = true,
            mappings = {},
          }
        end
      )
    end,
  },

  {
    "tpope/vim-surround",
    event = "InsertEnter",
    dependencies = { "tpope/vim-repeat" },
  },

  { "Raimondi/delimitMate", event = "InsertEnter" },

  {
    "mfussenegger/nvim-lint",
    event = "BufReadPost",
    config = function() req "core.plugins.lint" end,
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
    "cshuaimin/ssr.nvim",
    event = "BufReadPre",
    config = function() req "core.plugins.ssr" end,
  },

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
    event = "BufReadPre",
  },

  {
    "phaazon/hop.nvim",
    event = "WinEnter",
    config = function() req "core.plugins.hop" end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPre",
    dependencies = {
      "RRethy/vim-illuminate",
      "RRethy/nvim-treesitter-textsubjects",
      "nvim-treesitter/nvim-treesitter-textobjects",
      {
        "mfussenegger/nvim-treehopper",
        dependencies = {
          "phaazon/hop.nvim",
          config = function() req "core.plugins.hop" end,
        },
      },
      "kiyoon/treesitter-indent-object.nvim",
      "andymass/vim-matchup",
      "cshuaimin/ssr.nvim",
      "RRethy/nvim-treesitter-endwise",
      "nvim-treesitter/nvim-treesitter-refactor",
      "MunifTanjim/nui.nvim",
    },
    config = function() req "core.plugins.treesitter" end,
  },

  {
    "wellle/context.vim",
    event = "BufReadPre",
    config = function() req "core.plugins.context" end,
  },

  {
    "SirVer/ultisnips",
    event = "InsertEnter",
    dependencies = { "honza/vim-snippets" },
    config = function() req "core.plugins.ultisnips" end,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "quangnguyen30192/cmp-nvim-ultisnips",
      "tamago324/cmp-zsh",
      "hrsh7th/cmp-nvim-lsp",
      "ray-x/cmp-treesitter",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "hrsh7th/cmp-nvim-lsp-document-symbol",
    },
    config = function() req "core.plugins.cmp" end,
  },

  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-git" },
    keys = "<leader>g",
    config = function() req "core.plugins.fugitive" end,
  },

  {
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
  },

  {
    "folke/which-key.nvim",
    config = function() req "core.plugins.which-key" end,
  },

  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && yarn install",
    ft = "markdown",
  },

  {
    "mhartington/formatter.nvim",
    event = "BufReadPost",
    config = function() req "core.plugins.formatter" end,
  },

  {'liuchengxu/vista.vim', keys = {'<C-t>', }},

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      'ldelossa/litee.nvim',
      'ldelossa/litee-symboltree.nvim',
      "RRethy/vim-illuminate",
      "lukas-reineke/lsp-format.nvim",
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
      "simrat39/rust-tools.nvim",
      "Saecki/crates.nvim",
    },
    config = function() req "core.plugins.lsp" end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
    },
    config = function() req "core.plugins.telescope" end,
  },

  {
    "moll/vim-bbye",
    event = "BufReadPre",
    config = function()
      local function delete_and_hide(wipeout)
        local bufname = vim.fn.bufname(vim.fn.bufnr())
        if wipeout then
          vim.cmd(":Bwipeout " .. bufname)
        else
          vim.cmd(":Bdelete " .. bufname)
        end
        local tab = vim.fn.tabpagenr()
        local n_wins = #(vim.fn.tabpagebuflist(tab))
        if n_wins > 1 then vim.cmd ":hide" end
      end
      Keybinding.bind(
        { noremap = true, leader = true },
        { "bq", delete_and_hide, { desc = "Delete buffer" } },
        { "bQ", partial(delete_and_hide, true), { desc = "Wipeout buffer" } }
      )
      req "user.plugins.vim-bbye"
    end,
  },
}
