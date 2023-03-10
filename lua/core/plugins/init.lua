local lazy = require("lazy")
if not lazy then
	logger:error("Cannot load lazy.nvim. Fatal error")
	return
end

makepath(user, "plugins", "plugins")

user.plugins.plugins = require("core.plugins.plugins")

req("user.plugins.plugins")

lazy.setup(user.plugins.plugins, { lazy = true })
