local tagbar = plugins.get 'tagbar'
tagbar.mappings = {
    tagbar = {
        tagbar = {
            "n",
            "<C-t>",
            ":TagbarToggle<CR>",
            { desc = "Toggle tagbar" }
        }
    }
}

vim.g.tagbar_position = "leftabove vertical"
