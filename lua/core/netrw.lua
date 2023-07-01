vim.g.netrw_banner = 0

kbd.map_dict {
    netrw = {
        opts = {noremap=true},
        netrw = { "<leader>|", ":Lexplore <bar> vert resize 40<CR>", "Open netrw" },
        netrw_quickmap1 = {
            "g?",
            ":h netrw-quickmap<CR>",
            { event = "FileType", pattern = "netrw", desc = "Help" },
        }
    }
}
