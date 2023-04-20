local lazy = require "lazy"
if not lazy then error "Cannot load lazy.nvim. Fatal error" end

require 'core.plugins.plugins'

-- Package overrides 
req 'user/plugins/plugins'

-- Rest of the reqs will be the same as core/plugins/plugins with user dir 
-- In some doom plugin config file: 
-- ...
-- req 'user/plugins/<plugin-alias>'

-- Setup 
lazy.setup(dict.values(user.plugins.PLUGIN), { lazy = true })
