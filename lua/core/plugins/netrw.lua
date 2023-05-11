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

  setup = function(self)
    require("netrw").setup(self.config)
  end,
}
