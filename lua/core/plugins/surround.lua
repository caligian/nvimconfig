plugin.surround = {
  config = {},
  on_attach = function(self)
    require("nvim-surround").setup(self.config)
  end,
}
