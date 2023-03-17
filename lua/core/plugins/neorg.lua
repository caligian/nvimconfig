user.plugins.neorg = {
  config = {
    load = {
      ["core.defaults"] = {},
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
}

req "user.plugins.neorg"
require("neorg").setup(user.plugins.neorg.config)
