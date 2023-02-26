local ivy = V.require("telescope.themes").get_ivy()
local file_browser_actions = V.require("core.plugins.telescope_nvim.file_browser")
local buffer_actions = V.require("core.plugins.telescope_nvim.buffers")
user.plugins["telescope.nvim"] = {}
local T = V.merge(user.plugins["telescope.nvim"], ivy)

-- To seem more like emacs ivy
T.disable_devicons = true
T.layout_config.height = 0.6
T.previewer = false

--  Setup telescope default configuration
T.extensions = {
  file_browser = V.merge({
    disable_devicons = true,

    mappings = {
      n = {
        d = file_browser_actions.delete_recursively,
        l = file_browser_actions.luafile,
        ["<C-g>"] = file_browser_actions.git_init,
        ["<C-d>"] = file_browser_actions.open_in_netrw,
        ["<C-T>"] = file_browser_actions.touch,
      },
    },
  }, ivy),

  project = V.merge({
    hidden_files = false,
    order_by = "desc",
    search_by = "title",
    sync_with_nvim_tree = true,
  }, ivy),
}

T.pickers = {
  buffers = {
    mappings = {
      n = {
        x = buffer_actions.bwipeout,
        ["!"] = buffer_actions.nomodified,
        w = buffer_actions.save,
        r = buffer_actions.readonly,
      },
    },
  },
}

-- Setup telescope with extensions
-- Require user overrides
V.require("user.plugins.telescope_nvim")
V.require("telescope").setup(T)
V.require("telescope").load_extension("file_browser")
V.require("telescope").load_extension("project")

-- Start keymappings
local function picker(p)
  return function()
    require("telescope.builtin")[p](ivy)
  end
end

local opts = { noremap = true, leader = true, mode = "n" }
Keybinding.bind(
  opts,
  { "/", picker("grep_string"), { desc = "Grep string in workspace", name = "ts_grep" } },
  { "?", picker("live_grep"), { desc = "Live grep in workspace", name = "ts_live_grep" } },
  { "'", picker("marks"), { desc = "Show marks", name = "ts_marks" } },
  { '"', picker("registers"), { desc = "Show registers", name = "ts_registers" } },
  { "<leader>", picker("resume"), { desc = "Resume telescope", name = "ts_resume" } },
  { "ho", picker("vim_options"), { desc = "Show vim options", name = "ts_options" } },
  { ".", picker("find_files"), { desc = "Find files in workspace", name = "ts_ff" } },
  { "gf", picker("git_files"), { desc = "Do git ls-files", name = "ts_git_ls" } },
  { "bb", picker("buffers"), { desc = "Show buffers", name = "ts_buffers" } },
  { "fr", picker("oldfiles"), { desc = "Show recently opened files", name = "ts_mru" } },
  { "hm", picker("man_pages"), { desc = "Show man pages", name = "ts_man" } },
  { "hc", picker("colorscheme"), { desc = "Select colorscheme", name = "ts_colorscheme" } },
  { "lt", picker("treesitter"), { desc = "Telescope treesitter", name = "ts_treesitter" } },
  { "lr", picker("lsp_references"), { desc = "Show references", name = "ts_ref" } },
  {
    "ls",
    picker("lsp_document_symbols"),
    { desc = "Buffer symbols", name = "ts_document_symbols" },
  },
  {
    "lS",
    picker("lsp_workspace_symbols"),
    { desc = "Workspace symbols", name = "ts_workspace_symbols" },
  },
  { "ld", picker("diagnostics"), { desc = "Show LSP diagnostics", name = "ts_diagnostics" } },
  { "gC", picker("git_commits"), { desc = "Show commits", name = "ts_git_commits" } },
  { "gB", picker("git_bcommits"), { desc = "Show branch commits", name = "ts_branch_commits" } },
  { "g?", picker("git_status"), { desc = "Git status", name = "ts_git_status" } },
  { "ff", ":Telescope file_browser<CR>", { desc = "File browser", name = "ts_file_browser" } },
  { "p", ":Telescope project<CR>", { desc = "Project management", name = "ts_project" } }
)
