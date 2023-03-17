-- Textobjects are broken for some reason
user.plugins.treesitter = {
  config = {
    refactor = {
      navigation = {
        enable = true,
        keymaps = {
          goto_definition = "gnd",
          list_definitions = "gnD",
          list_definitions_toc = "gO",
          goto_next_usage = "<a-*>",
          goto_previous_usage = "<a-#>",
        },
      },
      highlight_definitions = {
        enable = true,
        clear_on_cursor_move = true,
      },
      smart_rename = {
        enable = true,
        keymaps = {
          smart_rename = "grr",
        },
      },
    },

    endwise = { enabled = true },

    matchup = { enable = true },

    ensure_installed = {
      "lua",
      "python",
      "ruby",
      "bash",
      "perl",
      "gitcommit",
      "git_rebase",
      "gitattributes",
      "gitignore",
    },

    auto_install = true,

    textsubjects = {
      enable = true,
      prev_selection = ",", -- (Optional) keymap to select the previous selection
      keymaps = {
        ["."] = "textsubjects-smart",
        [";"] = "textsubjects-container-outer",
        ["i;"] = "textsubjects-container-inner",
      },
    },

    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn", -- set to `false` to disable one of the mappings
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },

    textobjects = {
      lsp_interop = {
        enable = true,
        border = "none",
        floating_preview_opts = {},
        peek_definition_code = {
          ["gF"] = "@function.outer",
          ["gC"] = "@class.outer",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]]"] = { query = "@class.outer", desc = "Next class start" },
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
          ["]["] = "@class.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[["] = "@class.outer",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
          ["[]"] = "@class.outer",
        },
      },
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["al"] = "@loop.outer",
          ["il"] = "@loop.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["uc"] = "@comment.outer",
        },
        selection_modes = {
          ["@parameter.outer"] = "v",
          ["@function.outer"] = "V",
          ["@class.outer"] = "<c-v>",
        },
        include_surrounding_whitespace = true,
      },
    },

    highlight = {
      enable = true,
      disable = {},
      additional_vim_regex_highlighting = false,
    },
  },
}

--------------------------------------------------
--------------------------------------------------
-- nvim-treehopper
req "core.plugins.hop"

K.bind({ silent = true }, {
  "m",
  ':<C-U>lua require("tsht").nodes()<CR>',
  { mode = "o" },
}, {
  "m",
  ":lua require('tsht').nodes()<CR>",
  { noremap = true, mode = "x" },
})

--------------------------------------------------
-- Setup treesitter
req "user.plugins.treesitter"
require("nvim-treesitter.configs").setup(user.plugins.treesitter.config)
