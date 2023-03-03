local lazy = V.require("lazy")
if not lazy then
  logger:error("Cannot load lazy.nvim. Fatal error")
  return
end

V.makepath(user, "plugins", "plugins")

user.plugins.plugins = require("core.plugins.plugins")

V.require("user.plugins.plugins")

lazy.setup(user.plugins.plugins, { lazy = true })
