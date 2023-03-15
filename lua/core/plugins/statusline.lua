user.plugins.statusline = {
  theme = "evil_line",
  config = { statuslines = {} },
}

req "user.plugins.statusline"

local statusline = user.plugins.statusline
local windline = require "windline"

-- windline.setup(statusline.config)
require("wlsample." .. statusline.theme)
