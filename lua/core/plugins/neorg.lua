user.plugins["neorg"] = {
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
}

V.require("user.plugins.neorg")

require("neorg").setup(user.plugins["neorg"])
