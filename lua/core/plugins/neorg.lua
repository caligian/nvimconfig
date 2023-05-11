plugin.neorg = {
  config = {
    load = {
      ["core.defaults"] = {},
      ["core.export"] = {},
      ["core.norg.concealer"] = {},
      ["core.norg.manoeuvre"] = {},
      ["core.integrations.treesitter"] = {},
      ["core.keybinds"] = {},
      ["core.mode"] = {},

      ["core.export.markdown"] = {
        config = {
          extensions = "all",
          extension = "md",
        },
      },

      ["core.norg.completion"] = {
        config = {
          engine = "nvim-cmp",
          name = "[Neorg]",
        },
      },

      ["core.norg.dirman"] = {
        config = {
          workspaces = {
            work = "~/Work",
            college = "~/Work/College",
            iigl = "~/Work/IIGL",
          },
        },
      },
    },
  },

  setup = function(self)
    require("neorg").setup(self.config)
  end,
}
