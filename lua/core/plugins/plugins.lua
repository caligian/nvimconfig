user.plugins = { PLUGIN = {} }
local state = user.plugins.PLUGIN

use_plugin = setmetatable({}, {
  __newindex = function(self, name, conf)
    user.plugins[name] = user.plugins[name] or { config = {} }
    state[name] = state[name] or {}
    dict.merge(state[name], conf)
  end,

  __index = function(self, plugin) return user.plugins.PLUGIN[k] end,

  __call = function(self, name)
    user.plugins[name] = user.plugins[name] or { config = {} }
    state[name] = state[name] or {}

    return function(spec) return dict.merge(state[name], spec) end
  end,
})

local function load_plugin(s)
  return function() req("core/plugins/" .. s) end
end

--------------------------------------------------

use_plugin "filetype" {
  "nathom/filetype.nvim",
  priority = 500,
}

use_plugin "plenary" {
  "nvim-lua/plenary.nvim",
}

use_plugin "telescope" {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-telescope/telescope-fzy-native.nvim" },
  config = function()
    vim.defer_fn(function() req "core.plugins.telescope" end, 200)
  end,
}

use_plugin "dispatch" {
  "tpope/vim-dispatch",
  event = "BufReadPost",
  config = function() req "core.plugins.dispatch" end,
}

use_plugin "hy" {
  "hylang/vim-hy",
  ft = { "hy" },
}

use_plugin "notify" {
  "rcarriga/nvim-notify",
}

use_plugin "statusline" {
  "nvim-lualine/lualine.nvim",
  dependencies = { "rcarriga/nvim-notify" },
  config = load_plugin "statusline",
  priority = 400,
}

use_plugin "gitsigns" {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPost",
  config = load_plugin "git_signs",
}

use_plugin "indent-blankline" {
  "lukas-reineke/indent-blankline.nvim",
  event = "BufReadPost",
  config = function() req "core.plugins.indent-blankline" end,
}

use_plugin "align" {
  "junegunn/vim-easy-align",
  event = "BufReadPost",
  config = utils.log_pcall_wrap(
    function()
      K.bind(
        { leader = true, noremap = true },
        { "=", ":EasyAlign ", "Align" },
        { "=", ":'<,'>EasyAlign ", { mode = "v", desc = "Align" } }
      )
    end
  ),
}

use_plugin "neorg" {
  "nvim-neorg/neorg",
  ft = "norg",
  config = function() req "core.plugins.neorg" end,
}

use_plugin "suda.vim" {
  "lambdalisue/suda.vim",
  cmd = "SudaRead",
  config = function() vim.g.suda_smart_edit = 1 end,
}

-- Good opinionated themes
use_plugin "everforest" {
  "sainnhe/everforest",

  dependencies = {
    {
      "maxmx03/solarized.nvim",
      config = utils.log_pcall_wrap(function ()
        local solarized = require 'solarized'
        vim.o.background = 'dark'
        solarized:setup { config = {theme = 'neovim'} }
      end)
    },
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
  config = function() req "core.plugins.colorscheme" end,
  priority = 300,
}

use_plugin "vimtex" {
  "lervag/vimtex",
  config = function() req "core.plugins.vimtex" end,
  ft = "tex",
}

use_plugin "devicons" {
  "nvim-tree/nvim-web-devicons",
  config = function()
    local web = req "nvim-web-devicons"
    if web then web.setup {} end
  end,
}

use_plugin "netrw" {
  "prichrd/netrw.nvim",
  cmd = "Lexplore",
  config = utils.log_pcall_wrap(
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
  ),
}

use_plugin "surround" {
  "kylechui/nvim-surround",
  event = "InsertEnter",
  config = utils.log_pcall_wrap(
    function() require("nvim-surround").setup {} end
  ),
}

use_plugin "autopairs" {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = partial(req, "core.plugins.autopairs"),
}

use_plugin "lint" {
  "mfussenegger/nvim-lint",
  event = "BufReadPost",
  config = function() req "core.plugins.lint" end,
}

use_plugin "vim-wayland-clipboard" {
  "jasonccox/vim-wayland-clipboard",
  keys = '"',
}

use_plugin "startuptime" {
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

use_plugin "vim-commentary" {
  "tpope/vim-commentary",
  event = "BufReadPost",
}

use_plugin "vimtex" {
  "lervag/vimtex",
  ft = "tex",
  config = partial(req, "core/plugins/vimtex"),
}

use_plugin "fennel" {
  "jaawerth/fennel.vim",
  ft = "fennel",
}

use_plugin "conjure" {
  "Olical/conjure",
  ft = user.conjure_langs,
}

use_plugin "ssr" {
  "cshuaimin/ssr.nvim",
  event = "BufReadPost",
  config = function() req "core.plugins.ssr" end,
}

use_plugin "hop" {
  "phaazon/hop.nvim",
  event = "BufReadPost",
  config = function() req "core.plugins.hop" end,
}

use_plugin "treesitter" {
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
      dependencies = {
        "phaazon/hop.nvim",
        config = function() req "core.plugins.hop" end,
      },
    },
    "kiyoon/treesitter-indent-object.nvim",
    "andymass/vim-matchup",
    "cshuaimin/ssr.nvim",
    "nvim-treesitter/nvim-treesitter-refactor",
    "MunifTanjim/nui.nvim",
  },
  config = function() req "core.plugins.treesitter" end,
}

use_plugin "ultisnips" {
  "SirVer/ultisnips",
  event = "InsertEnter",
  dependencies = { "honza/vim-snippets" },
  config = function() req "core.plugins.ultisnips" end,
}

use_plugin "cmp" {
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
}

use_plugin "fugitive" {
  "tpope/vim-fugitive",
  dependencies = { "tpope/vim-git" },
  keys = {
    { "<leader>gs", ":Git stage %<CR>", "n", { desc = "Stage buffer" } },
    { "<leader>gc", ":Git commit <CR>", "n", { desc = "Commit buffer" } },
    { "<leader>gg", ":tab Git<CR>", "n", { desc = "Open Fugitive" } },
  },
}

use_plugin "tagbar" {
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
}

use_plugin "which-key" {
  "folke/which-key.nvim",
  config = function() 
    vim.defer_fn(function ()
      req "core.plugins.which-key" 
    end, 300) 
  end,
}

use_plugin "markdown-preview" {
  "iamcco/markdown-preview.nvim",
  build = "cd app && yarn install",
  ft = "markdown",
}

use_plugin "formatter" {
  "mhartington/formatter.nvim",
  event = "BufReadPost",
  config = function() req "core.plugins.formatter" end,
}

use_plugin "lsp" {
  "neovim/nvim-lspconfig",
  dependencies = {
    "lukas-reineke/lsp-format.nvim",
    "williamboman/mason.nvim",
    "mfussenegger/nvim-dap",
    "simrat39/rust-tools.nvim",
    "Saecki/crates.nvim",
  },
  config = function() req "core.plugins.lsp" end,
}

use_plugin "vim-bbye" {
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
      if n_wins > 1 then vim.cmd ":hide" end
    end

    Keybinding.bind(
      { noremap = true, leader = true },
      { "bq", delete_and_hide, { desc = "Delete buffer" } },
      { "bQ", partial(delete_and_hide, true), { desc = "Wipeout buffer" } }
    )

    req "user.plugins.vim-bbye"
  end),
}
