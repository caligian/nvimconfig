vim.cmd('packadd! telescope.nvim')
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
    ['.'] = {'buffers', 'Show buffers'},
    ['/'] = {'grep_string', 'Grep string in workspace'},
    ['?'] = {'live_grep', 'Live grep in workspace'},
    ['\''] = {'marks', 'Show marks'},
    ['<space>'] = {'resume', 'Resume telescope'},
    ho = {'vim_options', 'Show vim options'},
    ff = {'find_files', 'Find files in workspace'},
    gf = {'git_files', 'Do git ls-files'},
    bb = {'buffers', 'Show buffers'},
    fr = {'oldfiles', 'Show recently opened files'},
    bt = {'tags', 'Show tags'},
    hm = {'man_pages', 'Show man pages'},
    ht = {'colorscheme', 'Select colorscheme'},
    lr = {'lsp_references', 'Show references'},
    ls = {'lsp_document_symbols', 'Buffer symbols'},
    lS = {'lsp_workspace_symbols', 'Workspace symbols'},
    ld = {'diagnostics', 'Show LSP diagnostics'},
    gC = {'git_commits', 'Show commimts'},
    gB = {'git_bcommits', 'Show branch commits'},
    ['g?'] = {'git_status', 'Git status'},
}

for keys, picker in pairs(builtin_keybindings) do
    local p, desc = unpack(picker)
    local cb = builtin(p)
    vim.api.nvim_set_keymap('n', '<leader>' .. keys, '', {callback=cb, noremap=true, desc=desc})
end

vim.api.nvim_set_keymap(
  "n",
  "<leader>fF",
  '',
  { noremap = true, callback=telescope.extensions.file_browser.file_browser, desc='Open file browser' }
)

vim.api.nvim_set_keymap(
  "n",
  "<leader>p",
  '',
  { noremap = true, callback = telescope.extensions.project.project, desc='Project management' }
)
