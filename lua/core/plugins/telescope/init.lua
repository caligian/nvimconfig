local ivy = load_telescope().theme
local buffer_actions = require "core.plugins.telescope.actions.buffer"
local find_files_actions = require "core.plugins.telescope.actions.find-files"
local file_browser_actions = require "core.plugins.telescope.actions.file-browser"
local T = copy(ivy)
local telescope = {}

--------------------------------------------------------------------------------
-- Some default overrides
T.extensions = {
  file_browser = {
    hijack_netrw = true,
    mappings = {
      n = {
        x = file_browser_actions.delete,
        X = file_browser_actions.force_delete,
        ["%"] = file_browser_actions.touch,
      },
    },
  },
}

T.pickers = {
  buffers = {
    show_all_buffers = true,
    mappings = {
      n = {
        x = buffer_actions.bwipeout,
        ["!"] = buffer_actions.nomodified,
        w = buffer_actions.save,
        r = buffer_actions.readonly,
      },
    },
  },
  find_files = {
    mappings = {
      n = {
        n = find_files_actions.touch_and_open,
        ["%"] = find_files_actions.touch,
        x = find_files_actions.delete,
      },
    },
  },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Start keymappings
local function picker(p, conf)
  return function()
    require("telescope.builtin")[p](dict.merge(conf or {}, ivy))
  end
end

telescope.mappings = {
  opts = {
    noremap = true,
    leader = true,
  },
  grep = {
    "n",
    "/",
    function()
      picker("live_grep", { search_dirs = { vim.fn.expand "%:p" } })()
    end,
    { desc = "Grep string in workspace" },
  },
  live_grep = {
    "n",
    "?",
    picker "live_grep",
    { desc = "Live grep in workspace" },
  },
  marks = { "n", "'", picker "marks", { desc = "Show marks" } },
  registers = {
    "n",
    '"',
    picker "registers",
    { desc = "Show registers" },
  },
  resume = {
    "n",
    "<leader>",
    picker "resume",
    { desc = "Resume telescope" },
  },
  options = {
    "n",
    "ho",
    picker "vim_options",
    { desc = "Show vim options" },
  },
  find_files = {
    "n",
    "ff",
    function()
      picker("find_files", { cwd = vim.fn.expand "%:p:h" })()
    end,
    { desc = "Find files in workspace" },
  },
  git_files = {
    "n",
    "gf",
    picker "git_files",
    { desc = "Do git ls-files" },
  },
  buffers = { "n", "bb", picker "buffers", { desc = "Show buffers" } },
  oldfiles = {
    "n",
    "fr",
    picker "oldfiles",
    { desc = "Show recently opened files" },
  },
  man = { "n", "hm", picker "man_pages", { desc = "Show man pages" } },
  treesitter = {
    "n",
    "lt",
    picker "treesitter",
    { desc = "Telescope treesitter" },
  },
  lsp_references = {
    "n",
    "lr",
    picker "lsp_references",
    { desc = "Show references" },
  },
  lsp_document_symbols = {
    "n",
    "ls",
    picker "lsp_document_symbols",
    { desc = "Buffer symbols" },
  },
  lsp_workspace_symbols = {
    "n",
    "lS",
    picker "lsp_workspace_symbols",
    { desc = "Workspace symbols" },
  },
  -- lsp_buffer_diagnostics = {
  --     "ld",
  --     function()
  --         picker("diagnostics", { bufnr = 0 })()
  --     end,
  --     { desc = "Show buffer LSP diagnostics" },
  -- },
  -- lsp_diagnostics = {
  --     "l`",
  --     picker "diagnostics",
  --     { desc = "Show LSP diagnostics" },
  -- },
  git_commits = {
    "n",
    "gC",
    picker "git_commits",
    { desc = "Show commits" },
  },
  git_bcommits = {
    "n",
    "gB",
    picker "git_bcommits",
    { desc = "Show branch commits" },
  },
  git_status = {
    "n",
    "g?",
    picker "git_status",
    { desc = "Git status" },
  },
  command_history = {
    "n",
    "h;",
    picker "command_history",
    { desc = "Command history" },
  },
  colorschemes = {
    "n",
    "hc",
    picker "colorscheme",
    { desc = "Colorscheme picker" },
  },
  file_browser = {
    "n",
    "\\",
    function()
      require("telescope").extensions.file_browser.file_browser(ivy)
    end,
    { desc = "Open file browser" },
  },
}

function telescope:setup()
  local ts = require "telescope"
  ts.setup(T)
  ts.load_extension "file_browser"
end

return telescope
