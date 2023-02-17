local telescope = V.require("telescope")
local ivy = V.require("telescope.themes").get_ivy()
local file_browser_actions = V.require("core.plugins.telescope_nvim.file_browser")
local buffer_actions = V.require("core.plugins.telescope_nvim.buffers")
user.plugins["telescope.nvim"] = {}
local T = V.merge(user.plugins["telescope.nvim"], ivy)

-- To seem more like emacs ivy
T.disable_devicons = true
T.layout_config.height = 0.3
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
user.plugins["telescope.nvim"].kbd = {
  grep_string = Keybinding.bind(
    opts,
    { "/", picker("grep_string"), { desc = "Grep string in workspace" } }
  ),

  live_grep = Keybinding.bind(
    opts,
    { "?", picker("live_grep"), { desc = "Live grep in workspace" } }
  ),

  marks = Keybinding.bind(opts, { "'", picker("marks"), { desc = "Show marks" } }),

  registers = Keybinding.bind(opts, { '"', picker("registers"), { desc = "Show registers" } }),

  resume = Keybinding.bind(opts, { "<leader>", picker("resume"), { desc = "Resume telescope" } }),

  vim_options = Keybinding.bind(
    opts,
    { "ho", picker("vim_options"), { desc = "Show vim options" } }
  ),

  find_files = Keybinding.bind(
    opts,
    { ".", picker("find_files"), { desc = "Find files in workspace" } }
  ),

  git_files = Keybinding.bind(opts, { "gf", picker("git_files"), { desc = "Do git ls-files" } }),

  buffers = Keybinding.bind(opts, { "bb", picker("buffers"), { desc = "Show buffers" } }),

  oldfiles = Keybinding.bind(
    opts,
    { "fr", picker("oldfiles"), { desc = "Show recently opened files" } }
  ),

  man_pages = Keybinding.bind(opts, { "hm", picker("man_pages"), { desc = "Show man pages" } }),

  colorscheme = Keybinding.bind(
    opts,
    { "ht", picker("colorscheme"), { desc = "Select colorscheme" } }
  ),

  lsp_references = Keybinding.bind(
    opts,
    { "lr", picker("lsp_references"), { desc = "Show references" } }
  ),

  lsp_document_symbols = Keybinding.bind(
    opts,
    { "ls", picker("lsp_document_symbols"), { desc = "Buffer symbols" } }
  ),

  lsp_workspace_symbols = Keybinding.bind(
    opts,
    { "lS", picker("lsp_workspace_symbols"), { desc = "Workspace symbols" } }
  ),

  diagnostics = Keybinding.bind(
    opts,
    { "ld", picker("diagnostics"), { desc = "Show LSP diagnostics" } }
  ),

  git_commits = Keybinding.bind(opts, { "gC", picker("git_commits"), { desc = "Show commimts" } }),

  git_bcommits = Keybinding.bind(
    opts,
    { "gB", picker("git_bcommits"), { desc = "Show branch commits" } }
  ),

  git_status = Keybinding.bind(opts, { "g?", picker("git_status"), { desc = "Git status" } }),

  file_browser = Keybinding.bind(
    opts,
    { "fF", ":Telescope file_browser<CR>", { desc = "File browser" } }
  ),

  project = Keybinding.bind(
    opts,
    { "p", ":Telescope project<CR>", { desc = "Project management" } }
  ),
}

V.require("user.telescope_nvim.kbd")
