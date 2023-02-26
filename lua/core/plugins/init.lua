local lazy = V.require("lazy")
if not lazy then
  logger:error("Cannot load lazy.nvim. Fatal error")
  return
end

V.makepath(user, "plugins", "plugins")

user.plugins.plugins = {
  { "nvim-lua/plenary.nvim" },

  { "junegunn/vim-easy-align", event = "BufReadPre" },

  {
    "lambdalisue/suda.vim",
    config = function(...)
      vim.g.suda_smart_edit = 1
    end,
  },

  -- Good opinionated themes
  {
    "sainnhe/everforest",
    -- A hack to ensure that user.colorscheme is captured
    dependencies = {
      { "RRethy/nvim-base16" },
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
      require("core.plugins.colorscheme")
    end,
  },

  {
    "lervag/vimtex",
    config = function()
      V.require("core.plugins.vimtex")
    end,
    ft = "tex",
  },

  {
    "nvim-tree/nvim-web-devicons",
    event = "WinEnter",
    config = function()
      local web = V.require("nvim-web-devicons")
      if web then
        web.setup({})
      end
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    event = "WinEnter",
    config = function()
      V.require("core.plugins.nvim-tree")
    end,
  },

  {
    "beauwilliams/statusline.lua",
    config = function()
      local statusline = V.require("statusline")
      if statusline then
        statusline.tabline = false
        statusline.lsp_diagnostics = true
        vim.o.laststatus = 3
      end
    end,
  },

  { "tpope/vim-surround", event = "InsertEnter", dependencies = { "tpope/vim-repeat" } },

  { "justinmk/vim-sneak", event = "InsertEnter" },

  { "Raimondi/delimitMate", event = "InsertEnter" },

  {
    "mfussenegger/nvim-lint",
    event = "BufReadPost",
    config = function()
      V.require("core.plugins.nvim-lint")
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
      V.require("core.plugins.nvim-treesitter")
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      { "honza/vim-snippets" },
      { "SirVer/ultisnips" },
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
  },

  {
    "tpope/vim-fugitive",
    keys = "<leader>g",
    config = function()
      user.plugins["vim-fugitive"] = {
        minwidth = 47,
      }

      Keybinding.bind(
        { noremap = true, leader = true, mode = "n" },
        { "gs", ":Git stage %<CR>", { desc = "Stage buffer", desc = "stage_buffer" } },
        { "gc", ":Git commit <CR>", { desc = "Commit buffer", name = "commit buffer" } },
        {
          "gg",
          function()
            -- Tree-like Git status
            local minwidth = user.plugins["vim-fugitive"].minwidth
            local width = vim.fn.winwidth(0)
            local count = math.floor(vim.fn.winwidth(0) / 4)
            count = count < minwidth and minwidth or count

            vim.cmd(":vertical Git")
            vim.cmd(":vertical resize " .. count)
          end,
          { desc = "Open Fugitive", name = "fugitive" }
        }
      )

      V.require("user.plugins.vim-fugitive")
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
      V.require("user.plugins.tagbar")
    end,
  },

  {
    "folke/which-key.nvim",
    event = "WinEnter",
    config = function()
      V.require("core.plugins.which-key_nvim")
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
      V.require("core.plugins.formatter_nvim")
    end,
  },

  {
    "neovim/nvim-lspconfig",
    ft = V.filter(function(k)
      if V.haskey(Lang.langs, k, "server") then
        return k
      end
    end, V.keys(Lang.langs)),
    dependencies = {
      { "lukas-reineke/lsp-format.nvim" },
      { "SirVer/ultisnips" },
      { "williamboman/mason.nvim" },
      { "hrsh7th/nvim-cmp" },
    },
    config = function()
      V.require("core.plugins.nvim-lspconfig")
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
      V.require("core.plugins.telescope_nvim")
    end,
    event = "VimEnter",
  },

  {
    "moll/vim-bbye",
    event = "BufReadPre",
    config = function()
      local opts = { noremap = true, leader = true }
      Keybinding.bind(
        opts,
        { "bq", "<cmd>Bdelete<CR>", { desc = "Delete buffer" } },
        { "bQ", "<cmd>Bwiepout<CR>", { desc = "Wipeout buffer" } }
      )
      V.require("user.plugins.vim-bbye")
    end,
  },
}

V.require("user.plugins.plugins")

lazy.setup(user.plugins.plugins, { lazy = true })
