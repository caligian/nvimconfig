local fugitive = Plugin.get "fugitive"

fugitive.mappings = {
    opts = { leader = true, prefix = "g" },
    status = { "g", ":vert Git<CR>", { desc = "show status" } },
    stage = { "s", ":Git stage %<CR>", { desc = "stage buffer" } },
    add = { "a", ":Git add %<CR>", { desc = "add buffer" } },
    commit = { "c", ":Git commit<CR>", { desc = "commit buffer" } },
}

return fugitive
