local telescope = require 'telescope'
local ivy = require('telescope.themes').get_ivy()
ivy.disable_devicons = true
ivy.layout_config.height = 0.5
ivy.previewer = false
local file_browser_config = {
    disable_devicons = true,
}
local project_config = {
    hidden_files = false,
    order_by = "desc",
    search_by = "title",
    sync_with_nvim_tree = true,
}
telescope.setup {
    extensions = { project = project_config, file_browser = file_browser_config}
}
telescope.load_extension('file_browser')
telescope.load_extension('project')

local function get_picker(picker_type)
    return function(picker)
        return function()
            return require('telescope.' .. picker_type)[picker](ivy)
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
    user.builtin.kbd.noremap({ 'n', '<leader>' .. keys, cb, { desc = desc } })
end

user.builtin.kbd.noremap(
    { 'n', '<leader>ff',
    function ()
        telescope.extensions.file_browser.file_browser(ivy)
    end, desc = 'Open file browser' },
    { "n", "<leader>p",
    function ()
        telescope.extensions.project.project(ivy)
    end, { desc = 'Project management' } })
