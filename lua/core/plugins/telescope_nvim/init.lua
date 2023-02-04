local telescope = V.require 'telescope'
local ivy = V.require('telescope.themes').get_ivy()
local file_browser_actions = V.require 'core.plugins.telescope_nvim.file_browser'
local buffer_actions = V.require 'core.plugins.telescope_nvim.buffers'
user.plugins['telescope.nvim'] = {}
local T = V.merge(user.plugins['telescope.nvim'], ivy)

-- To seem more like emacs ivy
T.disable_devicons = true
T.layout_config.height = 0.5
T.previewer = false

--  Setup telescope default configuration
T.extensions = {
    file_browser = V.merge({
        disable_devicons = true,
        mappings = {
            n = {
                d = file_browser_actions.delete_recursively,
                l = file_browser_actions.luafile,
                ['<C-g>'] = file_browser_actions.git_init,
                ['<C-d>'] = file_browser_actions.open_in_netrw,
                ['<C-T>'] = file_browser_actions.touch,
            }
        }
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
                ['!'] = buffer_actions.nomodified,
                w = buffer_actions.save,
                r = buffer_actions.readonly,
            },
        }
    },
}

-- Setup telescope with extensions
-- Require user overrides
V.require 'user.plugins.telescope_nvim'
V.require('telescope').setup(T)
V.require('telescope').load_extension('file_browser')
V.require('telescope').load_extension('project')

-- Start keymappings
local function picker(p)
    return function() require('telescope.builtin')[p](ivy) end
end

local K = Keybinding({ noremap = true, leader = true, mode = 'n' })
K:bind {
    { '.', picker('buffers'), { desc = 'Show buffers' } },
    { '/', picker('grep_string'), { desc = 'Grep string in workspace' } },
    { '?', picker('live_grep'), { desc = 'Live grep in workspace' } },
    { '\'', picker('marks'), { desc = 'Show marks' } },
    { '"', picker('registers'), { desc = 'Show registers' } },
    { '<space>', picker('resume'), { desc = 'Resume telescope' } },
    { 'ho', picker('vim_options'), { desc = 'Show vim options' } },
    { 'fw', picker('find_files'), { desc = 'Find files in workspace' } },
    { 'gf', picker('git_files'), { desc = 'Do git ls-files' } },
    { 'bb', picker('buffers'), { desc = 'Show buffers' } },
    { 'fr', picker('oldfiles'), { desc = 'Show recently opened files' } },
    { 'hm', picker('man_pages'), { desc = 'Show man pages' } },
    { 'ht', picker('colorscheme'), { desc = 'Select colorscheme' } },
    { 'lr', picker('lsp_references'), { desc = 'Show references' } },
    { 'ls', picker('lsp_document_symbols'), { desc = 'Buffer symbols' } },
    { 'lS', picker('lsp_workspace_symbols'), { desc = 'Workspace symbols' } },
    { 'ld', picker('diagnostics'), { desc = 'Show LSP diagnostics' } },
    { 'gC', picker('git_commits'), { desc = 'Show commimts' } },
    { 'gB', picker('git_bcommits'), { desc = 'Show branch commits' } },
    { 'g?', picker('git_status'), { desc = 'Git status' } },
}

K:bind {
    { 'ff', ':Telescope file_browser<CR>', { desc = 'File browser' } },
    { 'p', ':Telescope project<CR>', { desc = 'Project management' } }
}
