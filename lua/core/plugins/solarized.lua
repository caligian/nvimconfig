plugin.solarized = {
  config = { theme = "neovim" },

  setup = function(self)
    vim.o.background = "dark"
    require("solarized"):setup(self.config)
  end,
}
