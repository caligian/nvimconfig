return {
  { "nvim-lua/plenary.nvim" },

  { "hylang/vim-hy", ft = { "hy" } },

  {
    "airblade/vim-gitgutter",
    event = "BufReadPost",
    config = function()
      req "core.plugins.git-gutter"
    end,
  },

  {
    "dhruvasagar/vim-buffer-history",
    event = "BufEnter",
  },

  {
    "easymotion/vim-easymotion",
    dependencies = { "tpope/vim-repeat" },
    config = function()
      vim.g.EasyMotion_do_mapping = 0
      vim.g.EasyMotion_smartcase = 1
      K.bind(
        { noremap = true },
        { "<localleader><localleader>", "<Plug>(easymotion-bd-jk)", "Goto line" },
        { "gH", "<Plug>(easymotion-linebackward)", "Current line backward search" },
        { "gJ", "<Plug>(easymotion-j)", "Goto line below" },
        { "gK", "<Plug>(easymotion-k)", "Goto line above" },
        { "gL", "<Plug>(easymotion-lineforward)", "Current line forward search" },
        { "g,", "<Plug>(easymotion-repeat)", "Motion repeat" },
        {'s', '<Plug>(easymotion-s2)'}
      )
    end,
    event = "BufReadPost",
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    config = function()
      local indent = req "indent_blankline"
      indent.setup {
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
    event = "BufReadPost",
    config = function()
      Keybinding.noremap("n", "<leader>=", ":EasyAlign ", { desc = "Align lines" })
      Keybinding.noremap("v", "<leader>=", ":'<,'>EasyAlign ", { desc = "Align lines" })
    end,
  },

  {
    "lambdalisue/suda.vim",
    event = "VimEnter",
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
    end,
    event = "VimEnter",
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
      req "core.plugins.tree"
    end,
  },

  { "tpope/vim-surround", event = "InsertEnter", dependencies = { "tpope/vim-repeat" } },

  { "Raimondi/delimitMate", event = "InsertEnter" },

  {
    "mfussenegger/nvim-lint",
    event = "BufReadPost",
    config = function()
      req "core.plugins.lint"
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
    event = "BufReadPre",
    dependencies = {
      "RRethy/nvim-treesitter-textsubjects",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      req "core.plugins.treesitter"
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
      { "hrsh7th/cmp-nvim-lsp" },
      { "ray-x/cmp-treesitter" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-nvim-lsp-signature-help" },
      { "hrsh7th/cmp-nvim-lsp-document-symbol" },
    },
    config = function()
      req "core.plugins.cmp"
    end,
  },

  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-git" },
    keys = "<leader>g",
    config = function()
      req "core.plugins.fugitive"
    end,
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
    ft = table.grep(table.keys(Lang.langs), function(k)
      if table.contains(Lang.langs, k, "server") then
        return k
      end
    end),
    dependencies = {
      { "lukas-reineke/lsp-format.nvim" },
      { "williamboman/mason.nvim" },
      { "mfussenegger/nvim-dap" },
      { "simrat39/rust-tools.nvim" },
      { "Saecki/crates.nvim" },
    },
    config = function()
      req "core.plugins.lsp"
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
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
      local function delete_and_hide(wipeout)
        local bufname = vim.fn.bufname(vim.fn.bufnr())
        if wipeout then
          vim.cmd(":Bwipeout " .. bufname)
        else
          vim.cmd(":Bdelete " .. bufname)
        end
        local tab = vim.fn.tabpagenr()
        local n_wins = #(vim.fn.tabpagebuflist(tab))
        if n_wins > 1 then
          vim.cmd ":hide"
        else
          vim.cmd ":b#"
        end
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
