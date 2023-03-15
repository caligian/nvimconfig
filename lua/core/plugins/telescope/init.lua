local ivy = require("telescope.themes").get_ivy()
local buffer_actions = require "core.plugins.telescope.buffers"
local git_status_actions = require "core.plugins.telescope.git_status"
user.plugins.telescope = { config = ivy }
local T = user.plugins.telescope.config

--------------------------------------------------------------------------------
-- Some default overrides
T.disable_devicons = true
T.layout_config.height = 0.3
T.previewer = false
T.extensions = {}
T.pickers = {
  buffers = {
    show_all_buffers = false,
    mappings = {
      n = {
        x = buffer_actions.bwipeout,
        ["!"] = buffer_actions.nomodified,
        w = buffer_actions.save,
        r = buffer_actions.readonly,
      },
    },
  },
  git_status = {
    mappings = {
      n = {
        s = git_status_actions.stage,
      },
    },
  },
}

--------------------------------------------------------------------------------
-- Setup extensions
T.extensions = {
  fzf = {
    fuzzy = true,
    override_generic_sorter = true,
    override_file_sorted = true,
    case_mode = "smart_case",
  },
}

--------------------------------------------------------------------------------
-- Setup telescope with extensions
-- Require user overrides
req "user.plugins.telescope"
local telescope = require "telescope"
telescope.setup(T)
telescope.load_extension "fzf"

--------------------------------------------------------------------------------
-- Start keymappings
local function picker(p)
  return function()
    require("telescope.builtin")[p](ivy)
  end
end

local opts = Keybinding.bind(
  { noremap = true, leader = true, mode = "n" },
  { "?", picker "grep_string", { desc = "Grep string in workspace", name = "ts_grep" } },
  { "/", picker "live_grep", { desc = "Live grep in workspace", name = "ts_live_grep" } },
  { "'", picker "marks", { desc = "Show marks", name = "ts_marks" } },
  { '"', picker "registers", { desc = "Show registers", name = "ts_registers" } },
  { "<leader>", picker "resume", { desc = "Resume telescope", name = "ts_resume" } },
  { "hv", picker "vim_options", { desc = "Show vim options", name = "ts_options" } },
  { ".", picker "find_files", { desc = "Find files in workspace", name = "ts_ff" } },
  { "ff", picker "git_files", { desc = "Do git ls-files", name = "ts_git_ls" } },
  { "bb", picker "buffers", { desc = "Show buffers", name = "ts_buffers" } },
  { "fr", picker "oldfiles", { desc = "Show recently opened files", name = "ts_mru" } },
  { "hm", picker "man_pages", { desc = "Show man pages", name = "ts_man" } },
  { "hc", picker "colorscheme", { desc = "Select colorscheme", name = "ts_colorscheme" } },
  { "lt", picker "treesitter", { desc = "Telescope treesitter", name = "ts_treesitter" } },
  { "lr", picker "lsp_references", { desc = "Show references", name = "ts_ref" } },
  {
    "ls",
    picker "lsp_document_symbols",
    { desc = "Buffer symbols", name = "ts_document_symbols" },
  },
  {
    "lS",
    picker "lsp_workspace_symbols",
    { desc = "Workspace symbols", name = "ts_workspace_symbols" },
  },
  { "ld", picker "diagnostics", { desc = "Show LSP diagnostics", name = "ts_diagnostics" } },
  { "gC", picker "git_commits", { desc = "Show commits", name = "ts_git_commits" } },
  { "gB", picker "git_bcommits", { desc = "Show branch commits", name = "ts_branch_commits" } },
  { "g?", picker "git_status", { desc = "Git status", name = "ts_git_status" } }
)
