plugin.devicons = {
  config = {},
  on_attach = function(self)
    local web = require "nvim-web-devicons"
    if web then
      web.setup(self.config)
    end
  end,
}
