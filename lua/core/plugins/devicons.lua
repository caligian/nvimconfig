local devicons = {}

function devicons:setup()
  local web = require "nvim-web-devicons"
  if web then
    web.setup(self.config)
  end
end

return devicons
