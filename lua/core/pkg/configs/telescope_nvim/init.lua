local telescope = builtin.require 'telescope'
local ivy = builtin.require('telescope.themes').get_ivy()
local file_browser_actions = builtin.require 'core.pkg.configs.telescope_nvim.file_browser'
local buffer_actions = builtin.require 'core.pkg.configs.telescope_nvim.buffers'

-- 
user.pkg['telescope.nvim'] = {}
local t = builtin.merge(user.pkg['telescope.nvim'], ivy)

-- To seem more like emacs ivy
t.disable_devicons = true
t.layout_config.height = 0.3
t.previewer = false

--  Setup telescope default configuration
t.extensions = {
    file_browser = builtin.merge({
        disable_devicons = true,
        mappings = {
            n = {
                d = file_browser_actions.delete_recursively,
                l = file_browser_actions.luafile,
                ['<C-g>'] = file_browser_actions.git_init,
                ['<C-d>'] = file_browser_actions.open_in_netrw,
                ['<C-t>'] = file_browser_actions.touch,
            }
        }
    }, ivy),
    project = builtin.merge({
        hidden_files = false,
        order_by = "desc",
        search_by = "title",
        sync_with_nvim_tree = true,
    }, ivy),
}

t.pickers = {
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
pcall(builtin.require, 'user.pkg.telescope_nvim')
builtin.require('telescope').setup(t)
builtin.require('telescope').load_extension('file_browser')
builtin.require('telescope').load_extension('project')

-- Setup builtin pickers keymaps
-- Convenience functions for getting pickers
local function get_picker(picker_type)
    return function(picker)
        return function()
            return builtin.require('telescope.' .. picker_type)[picker](ivy)
        end
    end
end

local builtin = get_picker('builtin')
local builtin_keybindings = {
    ['.'] = { 'buffers', 'Show buffers' },
    ['/'] = { 'grep_string', 'Grep string in workspace' },
    ['?'] = { 'live_grep', 'Live grep in workspace' },
    ['\''] = { 'marks', 'Show marks' },
    ['<space>'] = { 'resume', 'Resume telescope' },
    ho = { 'vim_options', 'Show vim options' },
    fw = { 'find_files', 'Find files in workspace' },
    gf = { 'git_files', 'Do git ls-files' },
    bb = { 'buffers', 'Show buffers' },
    fr = { 'oldfiles', 'Show recently opened files' },
    bt = { 'tags', 'Show tags' },
    hm = { 'man_pages', 'Show man pages' },
    ht = { 'colorscheme', 'Select colorscheme' },
    lr = { 'lsp_references', 'Show references' },
    ls = { 'lsp_document_symbols', 'Buffer symbols' },
    lS = { 'lsp_workspace_symbols', 'Workspace symbols' },
    ld = { 'diagnostics', 'Show LSP diagnostics' },
    gC = { 'git_commits', 'Show commimts' },
    gB = { 'git_bcommits', 'Show branch commits' },
    ['g?'] = { 'git_status', 'Git status' },
}

for keys, picker in pairs(builtin_keybindings) do
    local p, desc = unpack(picker)
    local cb = builtin(p)
    user.kbd.noremap('n', '<leader>' .. keys, cb, { desc = desc })
end

-- Extension keybindings
user.kbd.noremap('n', '<leader>ff', function() telescope.extensions.file_browser.file_browser(ivy) end, {desc = 'Open file browser'})
user.kbd.noremap('n', '<leader>pp', function() telescope.extensions.project.project(ivy) end, {desc = 'Project management'})
