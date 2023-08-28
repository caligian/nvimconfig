local neorg = Plugin.get "neorg"

neorg.config = {
    load = {
        ["core.defaults"] = {},
        ["core.export"] = {},
        ["core.concealer"] = {},
        ["core.integrations.treesitter"] = {},
        ["core.keybinds"] = {},
        ["core.mode"] = {},
        ["core.export.markdown"] = {
            config = {
                extensions = "all",
                extension = "md",
            },
        },
        ["core.completion"] = {
            config = {
                engine = "nvim-cmp",
                name = "[Neorg]",
            },
        },
        ["core.dirman"] = {
            config = {
                workspaces = {
                    work = "~/Work",
                    college = "~/Work/College",
                    iigl = "~/Work/IIGL",
                },
            },
        },
    },
}

function neorg:setup()
    require("neorg").setup(self.config)
end

return neorg
