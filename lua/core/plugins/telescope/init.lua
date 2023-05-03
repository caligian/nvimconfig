local _ = utils.telescope.load()
local ivy = _.ivy
local buffer_actions = require "core.plugins.telescope.buffer-actions"
local git_status_actions = require "core.plugins.telescope.git-status-actions"
local git_files_actions = require "core.plugins.telescope.git-files-actions"
local find_files_actions = require "core.plugins.telescope.find-files-actions"
local file_browser_actions =
  require "core.plugins.telescope.file-browser-actions"
user.plugins.telescope = { config = ivy }
local T = user.plugins.telescope.config

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
        ["b"] = file_browser_actions.add_bookmark,
        ["B"] = file_browser_actions.remove_bookmark,
      },
    },
  },
  fzy = {
    override_generic_sorter = true,
    override_file_sorter = true,
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
        b = buffer_actions.add_bookmark,
        B = buffer_actions.remove_bookmark,
      },
    },
  },
  find_files = {
    mappings = {
      n = {
        b = find_files_actions.add_bookmark,
        B = find_files_actions.remove_bookmark,
        x = find_files_actions.delete,
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
  git_files = {
    mappings = {
      n = {
        b = git_files_actions.add_bookmark,
        B = git_files_actions.remove_bookmark,
      },
    },
  },
}

--------------------------------------------------------------------------------
-- Setup telescope with extensions
-- Require user overrides
req "user.plugins.telescope"
local telescope = require "telescope"
telescope.setup(T)
telescope.load_extension "fzy_native"
telescope.load_extension "file_browser"

--------------------------------------------------------------------------------
-- Start keymappings
local function picker(p, conf)
  return function() require("telescope.builtin")[p](dict.merge(conf or {}, ivy)) end
end

local opts = Keybinding.bind(
  { noremap = true, leader = true, mode = "n" },
  {
    "/",
    function() picker("live_grep", { search_dirs = { vim.fn.expand "%:p" } })() end,
    { desc = "Grep string in workspace", name = "ts_grep" },
  },
  {
    "?",
    picker "live_grep",
    { desc = "Live grep in workspace", name = "ts_live_grep" },
  },
  { "'", picker "marks", { desc = "Show marks", name = "ts_marks" } },
  {
    '"',
    picker "registers",
    { desc = "Show registers", name = "ts_registers" },
  },
  {
    "<leader>",
    picker "resume",
    { desc = "Resume telescope", name = "ts_resume" },
  },
  {
    "hv",
    picker "vim_options",
    { desc = "Show vim options", name = "ts_options" },
  },
  {
    "ff",
    function() picker("find_files", { cwd = vim.fn.expand "%:p:h" })() end,
    { desc = "Find files in workspace", name = "ts_ff" },
  },
  { "gf", picker "git_files", { desc = "Do git ls-files", name = "ts_git_ls" } },
  { "bb", picker "buffers", { desc = "Show buffers", name = "ts_buffers" } },
  {
    "fr",
    picker "oldfiles",
    { desc = "Show recently opened files", name = "ts_mru" },
  },
  { "hm", picker "man_pages", { desc = "Show man pages", name = "ts_man" } },
  {
    "lt",
    picker "treesitter",
    { desc = "Telescope treesitter", name = "ts_treesitter" },
  },
  {
    "lr",
    picker "lsp_references",
    { desc = "Show references", name = "ts_ref" },
  },
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
  {
    "ld",
    function() picker("diagnostics", { bufnr = 0 })() end,
    { desc = "Show buffer LSP diagnostics", name = "ts_diagnostics" },
  },
  {
    "l`",
    picker "diagnostics",
    { desc = "Show LSP diagnostics", name = "ts_diagnostics" },
  },
  {
    "gC",
    picker "git_commits",
    { desc = "Show commits", name = "ts_git_commits" },
  },
  {
    "gB",
    picker "git_bcommits",
    { desc = "Show branch commits", name = "ts_branch_commits" },
  },
  { "g?", picker "git_status", { desc = "Git status", name = "ts_git_status" } },
  {
    "h;",
    picker "command_history",
    { desc = "Command history", name = "ts_git_status" },
  }
)

K.map(
  "n",
  "<leader>\\",
  function() require("telescope").extensions.file_browser.file_browser(ivy) end,
  "Open file browser"
)
