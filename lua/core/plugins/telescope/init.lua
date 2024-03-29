local M = {}

local function getivy()
  user.telescope()
  return user.telescope.theme
end

local function picker(p, conf)
  return function()
    require("telescope.builtin")[p](dict.merge(conf or {}, getivy()))
  end
end

local function O(overrides)
  return dict.merge(overrides, { noremap = true, leader = true })
end

M.mappings = {
  grep = {
    "n",
    "/",
    function()
      picker("live_grep", { search_dirs = { vim.fn.expand "%:p" } })()
    end,
    O { desc = "Grep string in workspace" },
  },

  live_grep = {
    "n",
    "?",
    picker "live_grep",
    O { desc = "Live grep in workspace" },
  },

  marks = {
    "n",
    "'",
    picker "marks",
    O { desc = "Show marks" },
  },

  registers = {
    "n",
    '"',
    picker "registers",
    O { desc = "Show registers" },
  },

  resume = {
    "n",
    "<leader>",
    picker "resume",
    O { desc = "Resume telescope" },
  },

  options = {
    "n",
    "ho",
    picker "vim_options",
    O { desc = "Show vim options" },
  },

  find_files = {
    "n",
    "ff",
    picker "find_files",
    O { desc = "Find files in workspace" },
  },

  git_files = {
    "n",
    "gf",
    picker "git_files",
    O { desc = "Do git ls-files" },
  },

  buffers = {
    "n",
    "bb",
    picker "buffers",
    O { desc = "Show buffers" },
  },

  -- oldfiles = {
  --   "n",
  --   "fr",
  --   picker "oldfiles",
  --   O { desc = "Show recently opened files" },
  -- },

  man = {
    "n",
    "hm",
    picker "man_pages",
    O { desc = "Show man pages" },
  },

  treesitter = {
    "n",
    "lt",
    picker "treesitter",
    O { desc = "Telescope treesitter" },
  },

  lsp_references = {
    "n",
    "lr",
    picker "lsp_references",
    O { desc = "Show references" },
  },

  lsp_document_symbols = {
    "n",
    "ls",
    picker "lsp_document_symbols",
    O { desc = "Buffer symbols" },
  },

  lsp_workspace_symbols = {
    "n",
    "lS",
    picker "lsp_workspace_symbols",
    O { desc = "Workspace symbols" },
  },
  -- lsp_buffer_diagnostics = {
  --     "ld",
  --     function()
  --         picker("diagnostics", { bufnr = 0 })()
  --     end,
  --     { desc = "Show buffer LSP diagnostics" },
  -- },
  lsp_diagnostics = {
    "n",
    "l`",
    picker "diagnostics",
    O { desc = "Show LSP diagnostics" },
  },

  git_commits = {
    "n",
    "gC",
    picker "git_commits",
    O { desc = "Show commits" },
  },

  git_bcommits = {
    "n",
    "gB",
    picker "git_bcommits",
    O { desc = "Show branch commits" },
  },

  git_status = {
    "n",
    "g?",
    picker "git_status",
    O { desc = "Git status" },
  },

  projects = {
    "n",
    "<leader>p",
    function()
      user.telescope()
      require("telescope").extensions.project.project(getivy())
    end,
    { desc = "Projects" },
  },

  command_history = {
    "n",
    "h;",
    picker "command_history",
    O { desc = "Command history" },
  },

  colorschemes = {
    "n",
    "hc",
    picker "colorscheme",
    O { desc = "Colorscheme picker" },
  },

  file_browser = {
    "n",
    "\\",
    function()
      require("telescope").extensions.file_browser.file_browser(getivy())
    end,
    O { desc = "Open file browser" },
  },

  oldfiles = {
    'n',
    'fr',
    function ()
      require("telescope").extensions.frecency.frecency(getivy())
    end,
    O {desc = 'Recent files'}
  }
}

local buffer_actions = require "core.plugins.telescope.actions.buffer"

local find_files_actions = require "core.plugins.telescope.actions.find-files"

local file_browser_actions = require "core.plugins.telescope.actions.file-browser"

M.config = {}

M.config.extensions = {
  file_browser = {
    hijack_netrw = false,
    mappings = {
      n = {
        x = file_browser_actions.multi_delete,
        X = file_browser_actions.multi_force_delete,
        ["%"] = file_browser_actions.touch,
      },
    },
  },
}

M.config.pickers = {
  buffers = {
    show_all_buffers = true,
    mappings = {
      n = {
        x = buffer_actions.multi_bwipeout,
        ["!"] = buffer_actions.multi_nomodified,
        w = buffer_actions.multi_save,
        r = buffer_actions.multi_readonly,
      },
    },
  },
  find_files = {
    mappings = {
      n = {
        ["%"] = find_files_actions.touch,
        x = find_files_actions.multi_delete,
      },
    },
  },
}

function M:setup()
  local ts = require "telescope"
  ts.setup(M.config)
  ts.load_extension "file_browser"
  ts.load_extension "project"
  ts.load_extension 'frecency'
end

return M
