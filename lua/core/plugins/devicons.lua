plugin.devicon = {
  config = {},
  setup = function(self, opts)
    opts = dict.merge(utils.copy(opts), self.config)
    local web = req "nvim-web-devicons"
    if web then
      web.setup(self.config)
    end
  end,
}
