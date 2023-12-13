-- Textobjects are broken for some reason
local treesitter = {}

treesitter.config = {
  refactor = {
    navigation = {
      enable = true,
      keymaps = {
        gotodefinition = "gnd",
        list_definitions = "gnD",
        list_definitions_toc = "gO",
        gotonext_usage = "<a-*>",
        gotoprevious_usage = "<a-#>",
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

  matchup = { enable = true },

  ensure_installed = {},

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
      gotonext_start = {
        ["]m"] = "@function.outer",
        ["]]"] = {
          query = "@class.outer",
          desc = "Next class start",
        },
      },
      gotonext_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      gotoprevious_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      gotoprevious_end = {
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
        ["Ci"] = "@conditional.inner",
        ["Ca"] = "@conditional.outer",
        ["bi"] = "@block.inner",
        ["ba"] = "@block.outer",
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
}

treesitter.mappings = {
  opts = { silent = true },
  show_in_operator = {
    "m",
    ':<C-U>lua require("tsht").nodes()<CR>',
    { mode = "o" },
  },
  show_in_visual = {
    "m",
    ":lua require('tsht').nodes()<CR>",
    { noremap = true, mode = "x" },
  },
}

function treesitter:setup()
  require("nvim-treesitter.configs").setup(self.config)
end

return treesitter
