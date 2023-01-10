local telescope = require 'telescope'
local ivy = require('telescope.themes').get_ivy()
ivy.disable_devicons = true
ivy.previewer = false

telescope.setup {
    extensions = {
        project = {
            hidden_files = true,
            order_by = "asc",
            search_by = "title",
            sync_with_nvim_tree = true,
            theme = 'ivy',
        },
        file_browser = {
            theme = 'ivy',
            disable_devicons = true,
        },
    }
}
telescope.load_extension('file_browser')
telescope.load_extension('project')

local function get_picker(picker_type)
    return function (picker)
        return function()
            return require('telescope.' .. picker_type)[picker](ivy)
        end
    end
end

local builtin = get_picker('builtin')
local builtin_keybindings = {
    ['.'] = 'buffers',
    ['/'] = 'grep_string',
    ['?'] = 'live_grep',
    ['\''] = 'marks',
    ['<space>'] = 'resume',
    ho = 'vim_options',
    ff = 'find_files',
    gf = 'git_files',
    bb = 'buffers',
    fr = 'oldfiles',
    bt = 'tags',
    hm = 'man_pages',
    ht = 'colorscheme',
    lr = 'lsp_references',
    ls = 'lsp_document_symbols',
    lS = 'lsp_workspace_symbols',
    ld = 'diagnostics',
    gC = 'git_commits',
    gB = 'git_bcommits',
    ['g?'] = 'git_status',
    ['l/'] = 'treesitter',
}

for keys, picker in pairs(builtin_keybindings) do
    local cb = builtin(picker)
    vim.api.nvim_set_keymap('n', '<leader>' .. keys, '', {callback=cb, noremap=true})
end

vim.api.nvim_set_keymap(
  "n",
  "<leader>fF",
  '',
  { noremap = true, callback=telescope.extensions.file_browser.file_browser }
)

vim.api.nvim_set_keymap(
  "n",
  "<leader>p",
  '',
  { noremap = true, callback = telescope.extensions.project.project }
)
