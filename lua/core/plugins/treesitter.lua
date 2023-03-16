-- Textobjects are broken for some reason
user.plugins.treesitter = {
  config = {
    refactor = {
      highlight_definitions = {
        enable = true,
        -- Set to false if you have an `updatetime` of ~100.
        clear_on_cursor_move = true,
      },
    },
    endwise = { enabled = true },
    matchup = { enable = true },
    pyfold = {enable=true, custom_foldtext=true},
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
    },
    highlight = {
      enable = true,
      disable = {},
      additional_vim_regex_highlighting = false,
    },
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["xi"] = "@attribute.inner",
        ["aa"] = "@attribute.outer",
        ["ib"] = "@block.inner",
        ["ab"] = "@block.outer",
        ["i."] = "@call.inner",
        ["a."] = "@call.outer",
        ["ic"] = "@class.inner",
        ["ac"] = "@class.outer",
        ["a;"] = "@comment.outer",
        ["i?"] = "@conditional.inner",
        ["a?"] = "@conditional.outer",
        ["i-"] = "@frame.inner",
        ["a-"] = "@frame.outer",
        ["if"] = "@function.inner",
        ["af"] = "@function.outer",
        ["i*"] = "@loop.inner",
        ["a*"] = "@loop.outer",
        ["i("] = "@parameter.inner",
        ["a("] = "@parameter.outer",
        ["as"] = "@statement.outer",
      },
      selection_modes = {
        ["@parameter.outer"] = "v",
        ["@function.outer"] = "V",
        ["@class.outer"] = "<c-v>",
      },
      include_surrounding_whitespace = true,
    },
  },
}

--------------------------------------------------
--------------------------------------------------
-- nvim-treehopper
require("tsht").move { side = "end" }

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
