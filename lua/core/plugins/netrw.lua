local netrw = plugin.get "netrw"
netrw = {
    icons = {
        symlink = "",
        directory = "",
        file = "",
    },
    use_devicons = true,
    mappings = {},
}

function netrw:setup()
    require("netrw").setup(self.config)
end
