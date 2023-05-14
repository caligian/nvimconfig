plugin.solarized = {
  config = { theme = "neovim" },

  on_attach = function(self)
    vim.o.background = "dark"
    require("solarized"):setup(self.config)
  end,
}
