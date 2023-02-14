V.require("lazy")

return require("lazy").setup({
  { "nvim-lua/plenary.nvim" },

  -- Good opinionated themes
  {
    "folke/tokyonight.nvim",
    dependencies = {
      { "nyoom-engineering/oxocarbon.nvim" },
      { "bluz71/vim-nightfly-colors" },
      { "bluz71/vim-moonfly-colors" },
      { "folke/lsp-colors.nvim" },
      { "savq/melange-nvim" },
      { "AlexvZyl/nordic.nvim" },
      { "lewpoly/sherbet.nvim" },
    },
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
      local tree = V.require("nvim-tree")
      if tree then
        V.require("user.nvim-tree_lua")
        tree.setup(user.plugins["nvim-tree"])

        local opts = { noremap = true, leader = true }
        user.plugins["nvim-tree"] = {
          kbd = {
            toggle_nvim_tree = Keybinding.bind(
              opts,
              { "|", ":NvimTreeToggle<CR>", "Focus tree explorer" }
            ),
            focus_nvim_tree = Keybinding.bind(
              opts,
              { "\\", ":NvimTreeFocus<CR>", "Toggle tree explorer" }
            ),
          },
        }
        V.require("user.plugins.nvim-tree.kbd")
      end
    end,
  },

  {
    "beauwilliams/statusline.lua",
    config = function()
      local statusline = V.require("statusline")
      if statusline then
        statusline.tabline = true
        statusline.lsp_diagnostics = true
        vim.o.laststatus = 3
      end
    end,
  },

  { "tpope/vim-surround", event = "InsertEnter", dependencies = { "tpope/vim-repeat" } },

  { "justinmk/vim-sneak", event = "InsertEnter" },

  { "Raimondi/delimitMate", event = "InsertEnter" },

  { "psliwka/vim-smoothie", event = "WinEnter" },

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
    ft = {
      "clojure",
      "fennel",
      "common-lisp",
      "guile",
      "hy",
      "janet",
      "julia",
      "lua",
      "python",
      "racket",
      "rust",
      "scheme",
    },
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
      { "hrsh7th/cmp-buffer" },
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
      local opts = { noremap = true, leader = true, mode = "n" }
      user.plugins["vim-fugitive"] = {
        minwidth = 47,
        kbd = {
          git_status = Keybinding.bind(opts, {
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
          }),
          git_stage = Keybinding.bind(opts, { "gs", ":Git stage %<CR>", "Stage buffer" }),
          git_commit = Keybinding.bind(opts, { "gc", ":Git commit <CR>", "Commit buffer" }),
        },
      }
      V.require("user.plugins.vim-fugitive")
    end,
  },

  {
    "preservim/tagbar",
    keys = "<C-t>",
    config = function()
      user.plugins["tagbar"] = {
        kbd = {
          open_tagbar = Keybinding.noremap(
            "n",
            "<C-t>",
            ":TagbarToggle<CR>",
            { desc = "Toggle tagbar" }
          ),
        },
      }
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
      { "hrsh7th/nvim-cmp" },
      { "nvim-telescope/telescope-file-browser.nvim" },
      { "nvim-telescope/telescope-project.nvim" },
      { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
    },
    config = function()
      V.require("core.plugins.telescope_nvim")
    end,
  },

  {
    "moll/vim-bbye",
    event = "BufReadPre",
    config = function()
      local opts = { noremap = true, leader = true }
      user.plugins["vim-bbye"] = {
        kbd = {
          delete_buffer = Keybinding.bind(
            opts,
            { "bq", "<cmd>Bdelete<CR>", { desc = "Delete buffer" } }
          ),
          wipeout_buffer = Keybinding.bind(
            opts,
            { "bQ", "<cmd>Bwipeout<CR>", { desc = "Wipeout buffer" } }
          ),
        },
      }
      V.require("user.plugins.vim-bbye")
    end,
  },
}, { lazy = true })
