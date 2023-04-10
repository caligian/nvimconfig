local plugins = {
  { "nvim-lua/plenary.nvim", priority = 500 },

  { "nathom/filetype.nvim", priority = 300 },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-telescope/telescope-fzy-native.nvim" },
    config = partial(req, "core.plugins.telescope"),
  },

  {
    "tpope/vim-dispatch",
    event = "BufReadPost",
    config = function()
      req "core.plugins.dispatch"
    end,
  },

  { "hylang/vim-hy", ft = { "hy" } },

  { "rcarriga/nvim-notify" },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "rcarriga/nvim-notify",
    },
    config = function()
      req "core.plugins.statusline"
    end,
    priority = 400,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPost",
    config = function()
      req "core.plugins.gitsigns"
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = "BufReadPost",
    config = function()
      req "core.plugins.indent-blankline"
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
    config = utils.log_pcall_wrap(function()
      K.bind(
        { leader = true, noremap = true },
        { "=", ":EasyAlign ", "Align" },
        { "=", ":'<,'>EasyAlign ", { mode = "v", desc = "Align" } }
      )
    end),
  },

  {
    "lambdalisue/suda.vim",
    cmd = "SudaRead",
    config = function()
      vim.g.suda_smart_edit = 1
    end,
  },

  -- Good opinionated themes
  {
    "sainnhe/everforest",
    -- A hack to ensure that all colorschemes are loaded at once
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
    config = function()
      req "core.plugins.colorscheme"
    end,
    priority = 10000,
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
    "prichrd/netrw.nvim",
    cmd = "Lexplore",
    config = utils.log_pcall_wrap(function()
      require("netrw").setup {
        icons = {
          symlink = "",
          directory = "",
          file = "",
        },
        use_devicons = true,
        mappings = {},
      }
    end),
  },

  {
    "kylechui/nvim-surround",
    event = "InsertEnter",
    config = utils.log_pcall_wrap(function()
      require("nvim-surround").setup {}
    end),
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = utils.log_pcall_wrap(function()
      require("nvim-autopairs").setup {}
    end),
  },

  { 
    "windwp/nvim-autopairs", 
    event = "InsertEnter", 
    config = partial(req, 'core.plugins.autopairs') 
  },

  {
    "mfussenegger/nvim-lint",
    event = "BufReadPost",
    config = function()
      req "core.plugins.lint"
    end,
  },

  { "jasonccox/vim-wayland-clipboard", keys = '"' },

  { "dstein64/vim-startuptime", cmd = "StartupTime" },

  { "tpope/vim-commentary", event = "BufReadPost" },

  { "lervag/vimtex", ft = "tex" },

  { "jaawerth/fennel.vim", ft = "fennel" },

  {
    "Olical/conjure",
    ft = user.conjure_langs,
  },

  {
    "cshuaimin/ssr.nvim",
    event = "BufReadPost",
    config = function()
      req "core.plugins.ssr"
    end,
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
    event = "BufReadPost",
  },

  {
    "phaazon/hop.nvim",
    event = "BufReadPost",
    config = function()
      req "core.plugins.hop"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = "BufReadPost",
    dependencies = {
      "RRethy/vim-illuminate",
      "RRethy/nvim-treesitter-textsubjects",
      "nvim-treesitter/nvim-treesitter-textobjects",
      {
        "mfussenegger/nvim-treehopper",
        dependencies = {
          "phaazon/hop.nvim",
          config = function()
            req "core.plugins.hop"
          end,
        },
      },
      "kiyoon/treesitter-indent-object.nvim",
      "andymass/vim-matchup",
      "cshuaimin/ssr.nvim",
      "RRethy/nvim-treesitter-endwise",
      "nvim-treesitter/nvim-treesitter-refactor",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      req "core.plugins.treesitter"
    end,
  },

  {
    "wellle/context.vim",
    event = "BufReadPost",
    config = function()
      req "core.plugins.context"
    end,
  },

  {
    "SirVer/ultisnips",
    event = "InsertEnter",
    dependencies = { "honza/vim-snippets" },
    config = function()
      req "core.plugins.ultisnips"
    end,
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
    config = function()
      req "core.plugins.cmp"
    end,
  },

  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-git" },
    keys = {
      { "<leader>gs", ":Git stage %<CR>", "n", { desc = "Stage buffer" } },
      { "<leader>gc", ":Git commit <CR>", "n", { desc = "Commit buffer" } },
      { "<leader>gg", ":tab Git<CR>", "n", { desc = "Open Fugitive" } },
    },
  },

  {
    "preservim/tagbar",
    keys = "<C-t>",
    event = "BufReadPost",
    config = utils.log_pcall_wrap(function()
      Keybinding.noremap(
        "n",
        "<C-t>",
        ":TagbarToggle<CR>",
        { desc = "Toggle tagbar", name = "tagbar" }
      )
      vim.g.tagbar_position = "leftabove vertical"
      req "user.plugins.tagbar"
    end),
  },

  {
    "folke/which-key.nvim",
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

  { "liuchengxu/vista.vim", keys = { "<C-t>" } },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "lukas-reineke/lsp-format.nvim",
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
      "simrat39/rust-tools.nvim",
      "Saecki/crates.nvim",
      "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    },
    config = function()
      req "core.plugins.lsp"
    end,
  },

  {
    "moll/vim-bbye",
    event = "BufReadPost",
    config = utils.log_pcall_wrap(function()
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
        end
      end
      Keybinding.bind(
        { noremap = true, leader = true },
        { "bq", delete_and_hide, { desc = "Delete buffer" } },
        { "bQ", partial(delete_and_hide, true), { desc = "Wipeout buffer" } }
      )
      req "user.plugins.vim-bbye"
    end),
  },
}

local names = {}
table.each(plugins, function(spec)
  local x = path.basename(spec[1])
  names[x] = spec
end)

return names
