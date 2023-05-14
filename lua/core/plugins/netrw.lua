plugin.netrw = {
  config = {
    icons = {
      symlink = "",
      directory = "",
      file = "",
    },
    use_devicons = true,
    mappings = {},
  },

  on_attach = function(self)
    require("netrw").setup(self.config)
  end,
}
