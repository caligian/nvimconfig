local netrw = Plugin.get "netrw"

netrw.config = {
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

return netrw
